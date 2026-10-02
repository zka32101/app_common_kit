import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_frequency_controller.dart';
import 'ad_rules.dart';
import 'ads_backend.dart';
import 'google_ads_backend.dart';

/// 広告の表示可否を一手に握る入口。
///
/// - noads / premium（[adsHidden] が true）の間は、SDK を初期化せず何も出さない。
/// - インタースティシャルは [InterstitialTrigger]（セッション終了・模擬試験結果）のみ。
/// - バナーは [BannerPlacement]（ホーム・結果・苦手特訓）のみ。
///   出題中・解説表示中の契機/場所は型として存在しないため呼び出せない。
class AdGate {
  AdGate._(this._config, this._backend, this._frequency, this._adsHidden)
      : _rules = _config.rules;

  final AdConfig _config;
  final AdsBackend _backend;
  final AdFrequencyController _frequency;
  final bool Function() _adsHidden;

  AdRules _rules;
  bool _ready = false;

  /// 初期化。[adsHidden] には `() => entitlementService.state.adsHidden` を渡す。
  /// [backend] / [isRelease] はテスト用の差し替え。
  static Future<AdGate> init({
    required AdConfig config,
    required bool Function() adsHidden,
    AdsBackend? backend,
    SharedPreferences? prefs,
    DateTime Function()? clock,
    bool isRelease = kReleaseMode,
  }) async {
    config.unitIds.assertNoTestIdsInRelease(isRelease: isRelease);
    final gate = AdGate._(
      config,
      backend ?? GoogleAdsBackend(),
      AdFrequencyController(
        prefs ?? await SharedPreferences.getInstance(),
        clock: clock,
      ),
      adsHidden,
    );
    await gate._ensureReady();
    return gate;
  }

  /// 有料（広告非表示）の間は初期化しない。後から無料に戻った場合は遅延初期化する。
  Future<bool> _ensureReady() async {
    if (_adsHidden()) return false;
    if (!_ready) {
      _ready = await _backend.initialize(_config);
      if (_ready) await _backend.preloadInterstitial();
    }
    return _ready;
  }

  /// Remote Config 等で取得したルールで上書きする。
  void updateRules(AdRules rules) => _rules = rules;

  /// 契機に達したときに呼ぶ。表示したら true。
  Future<bool> maybeShowInterstitial(InterstitialTrigger trigger) async {
    if (!await _ensureReady()) return false;
    if (!_frequency.canShowInterstitial(_rules)) return false;
    if (!_backend.isInterstitialReady) {
      await _backend.preloadInterstitial();
      return false;
    }
    final shown = await _backend.showInterstitial();
    if (shown) await _frequency.recordInterstitialShown();
    await _backend.preloadInterstitial();
    return shown;
  }

  /// 「今日の特訓 10 問」追加などの任意視聴用。有料ユーザーには不要なので false。
  Future<bool> showRewarded() async {
    if (!await _ensureReady()) return false;
    return _backend.showRewarded();
  }

  /// バナー。非表示条件では何も描画しない。
  Widget banner(BannerPlacement placement) {
    if (_adsHidden() || !_ready) return const SizedBox.shrink();
    return _backend.buildBanner(placement);
  }
}
