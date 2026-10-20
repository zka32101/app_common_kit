import 'package:flutter/foundation.dart' show setEquals;

/// 権利名（RevenueCat の Entitlement ID）。
class EntitlementIds {
  const EntitlementIds({this.noAds = 'noads', this.premium = 'premium'});

  final String noAds;
  final String premium;
}

/// 現在の権利の状態。
class EntitlementState {
  const EntitlementState({
    this.hasNoAds = false,
    this.hasPremium = false,
    this.premiumExpiresAt,
    this.extra = const {},
  });

  static const free = EntitlementState();

  final bool hasNoAds;
  final bool hasPremium;

  /// premium の期限。買い切り（無期限）や未所持の場合は null。
  final DateTime? premiumExpiresAt;

  /// noads / premium 以外で有効な権利ID（追加パックなど）。アプリごとに自由に決める。
  final Set<String> extra;

  /// 権利ID [id] を持っているか。
  bool has(String id) => extra.contains(id);

  /// 広告を出さない状態か。noads または premium のどちらかで非表示。
  bool get adsHidden => hasNoAds || hasPremium;

  @override
  bool operator ==(Object other) =>
      other is EntitlementState &&
      other.hasNoAds == hasNoAds &&
      other.hasPremium == hasPremium &&
      other.premiumExpiresAt == premiumExpiresAt &&
      setEquals(other.extra, extra);

  @override
  int get hashCode => Object.hash(
        hasNoAds,
        hasPremium,
        premiumExpiresAt,
        Object.hashAllUnordered(extra),
      );

  @override
  String toString() =>
      'EntitlementState(noAds: $hasNoAds, premium: $hasPremium, expires: $premiumExpiresAt, extra: $extra)';
}

/// 購入できる商品（RevenueCat の Offering の Package に相当）。
class EntitlementOffer {
  const EntitlementOffer({
    required this.id,
    required this.productId,
    required this.title,
    required this.priceString,
  });

  /// [EntitlementService.purchaseOffer] に渡す識別子。
  final String id;

  /// ストア側の商品ID。
  final String productId;
  final String title;

  /// 通貨記号付きの表示用価格（例: ¥300）。
  final String priceString;
}

/// 購入結果。
enum PurchaseOutcome { success, cancelled, blockedByGate, failed }
