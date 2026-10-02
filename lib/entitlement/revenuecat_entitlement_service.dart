import 'dart:async';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'entitlement_service.dart';
import 'entitlement_state.dart';

/// RevenueCat 実装。公開 SDK キーは引数で渡す（コミットしない）。
///
/// 期間パス（30日/90日）は非更新型、買い切りは非消耗型。期限は RevenueCat の
/// Entitlement の expirationDate で管理される。
class RevenueCatEntitlementService implements EntitlementService {
  RevenueCatEntitlementService._(this._ids, this._beforePurchase);

  final EntitlementIds _ids;
  final BeforePurchase? _beforePurchase;
  final _controller = StreamController<EntitlementState>.broadcast();
  EntitlementState _state = EntitlementState.free;

  /// SDK を設定して初期状態を取得する。
  static Future<RevenueCatEntitlementService> init({
    required String publicSdkKey,
    String? appUserId,
    EntitlementIds ids = const EntitlementIds(),
    BeforePurchase? beforePurchase,
  }) async {
    final service = RevenueCatEntitlementService._(ids, beforePurchase);
    await Purchases.configure(
      PurchasesConfiguration(publicSdkKey)..appUserID = appUserId,
    );
    Purchases.addCustomerInfoUpdateListener(service._apply);
    try {
      service._apply(await Purchases.getCustomerInfo());
    } on PlatformException {
      // オフライン等。無料状態で開始し、更新リスナーで追従する。
    }
    return service;
  }

  /// CustomerInfo から状態を導出する。
  static EntitlementState stateFrom(CustomerInfo info, EntitlementIds ids) {
    final active = info.entitlements.active;
    final premium = active[ids.premium];
    final expires = premium?.expirationDate;
    return EntitlementState(
      hasNoAds: active.containsKey(ids.noAds),
      hasPremium: premium != null,
      premiumExpiresAt: expires == null ? null : DateTime.tryParse(expires),
    );
  }

  EntitlementState _apply(CustomerInfo info) {
    final next = stateFrom(info, _ids);
    if (next != _state) {
      _state = next;
      _controller.add(next);
    }
    return _state;
  }

  @override
  EntitlementState get state => _state;

  @override
  Stream<EntitlementState> get stateStream => _controller.stream;

  @override
  Future<PurchaseOutcome> purchase(String productId) async {
    final gate = _beforePurchase;
    if (gate != null && !await gate(productId)) {
      return PurchaseOutcome.blockedByGate;
    }
    try {
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) return PurchaseOutcome.failed;
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(products.first));
      _apply(result.customerInfo);
      return PurchaseOutcome.success;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError
          ? PurchaseOutcome.cancelled
          : PurchaseOutcome.failed;
    }
  }

  @override
  Future<EntitlementState> restore() async =>
      _apply(await Purchases.restorePurchases());

  @override
  Future<EntitlementState> logIn(String appUserId) async =>
      _apply((await Purchases.logIn(appUserId)).customerInfo);

  @override
  Future<EntitlementState> logOut() async => _apply(await Purchases.logOut());

  @override
  void dispose() => _controller.close();
}
