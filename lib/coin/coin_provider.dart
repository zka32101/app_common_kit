import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coin_rules.dart';
import 'coin_service.dart';
import 'shop.dart';

/// アプリ側で上書きして使う。
///
/// ```dart
/// ProviderScope(overrides: [
///   coinServiceProvider.overrideWithValue(CoinService(
///     store: SharedPreferencesCoinStore('bike'), shop: myShopItems)),
/// ])
/// ```
final coinServiceProvider = Provider<CoinService>(
  (ref) => throw UnimplementedError('coinServiceProvider を override してください'),
);

class CoinState {
  const CoinState({
    this.balance = 0,
    this.totalEarned = 0,
    this.owned = const {},
    this.equipped = const {},
    this.lastGrant,
    this.recent = const [],
  });

  final int balance;
  final int totalEarned;
  final Set<String> owned;
  final Map<String, String> equipped;

  /// 直近の付与（画面で小さく控えめに知らせる用）。
  final CoinGrant? lastGrant;

  /// [CoinNotifier.takeRecent] を最後に呼んでから付与された分（新しい順ではなく付与順）。
  /// 結果画面のコイン内訳（`CoinBreakdownCard`）に使う。
  final List<CoinGrant> recent;
}

class CoinNotifier extends Notifier<CoinState> {
  CoinService get _s => ref.read(coinServiceProvider);

  @override
  CoinState build() => _snapshot();

  final List<CoinGrant> _recent = [];

  CoinState _snapshot({CoinGrant? grant}) => CoinState(
        balance: _s.balance,
        totalEarned: _s.totalEarned,
        owned: _s.ownedItemIds,
        equipped: _s.equipped,
        lastGrant: grant,
        recent: List.unmodifiable(_recent),
      );

  /// 溜まった付与の履歴を取り出して空にする（学習セッションの開始時・終了時に呼ぶ）。
  List<CoinGrant> takeRecent() {
    final taken = List<CoinGrant>.of(_recent);
    _recent.clear();
    state = _snapshot();
    return taken;
  }

  Future<void> load() async {
    await _s.load();
    state = _snapshot();
  }

  Future<CoinGrant?> grant(CoinEvent e) async {
    final g = await _s.grant(e);
    if (g != null) _recent.add(g);
    state = _snapshot(grant: g);
    return g;
  }

  Future<PurchaseResult> purchase(String itemId) async {
    final r = await _s.purchase(itemId);
    state = _snapshot();
    return r;
  }

  Future<bool> equip(String itemId) async {
    final ok = await _s.equip(itemId);
    state = _snapshot();
    return ok;
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
