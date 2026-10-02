import 'dart:async';

import 'entitlement_service.dart';
import 'entitlement_state.dart';

/// テスト・プレビュー用のモック実装。
class FakeEntitlementService implements EntitlementService {
  FakeEntitlementService({
    EntitlementState initial = EntitlementState.free,
    this.beforePurchase,
    this.grantOnPurchase,
  }) : _state = initial;

  final BeforePurchase? beforePurchase;

  /// productId → 購入後の状態。未指定の productId は failed。
  final Map<String, EntitlementState>? grantOnPurchase;

  final _controller = StreamController<EntitlementState>.broadcast();
  EntitlementState _state;

  /// restore() で復元される状態。
  EntitlementState? restorable;

  @override
  EntitlementState get state => _state;

  @override
  Stream<EntitlementState> get stateStream => _controller.stream;

  void setState(EntitlementState next) {
    if (next == _state) return;
    _state = next;
    _controller.add(next);
  }

  @override
  Future<PurchaseOutcome> purchase(String productId) async {
    final gate = beforePurchase;
    if (gate != null && !await gate(productId)) {
      return PurchaseOutcome.blockedByGate;
    }
    final granted = grantOnPurchase?[productId];
    if (granted == null) return PurchaseOutcome.failed;
    setState(granted);
    return PurchaseOutcome.success;
  }

  @override
  Future<EntitlementState> restore() async {
    final r = restorable;
    if (r != null) setState(r);
    return _state;
  }

  @override
  Future<EntitlementState> logIn(String appUserId) async => _state;

  @override
  Future<EntitlementState> logOut() async => _state;

  @override
  void dispose() => _controller.close();
}
