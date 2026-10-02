import 'package:shared_preferences/shared_preferences.dart';

import 'ad_rules.dart';

/// インタースティシャルの頻度制御（最短間隔・日次上限）。ローカルに保存し、
/// 日付が変わると日次カウントが自動でリセットされる。
class AdFrequencyController {
  AdFrequencyController(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const _kLastShown = 'app_common_kit.ads.last_shown_ms';
  static const _kCount = 'app_common_kit.ads.daily_count';
  static const _kDay = 'app_common_kit.ads.daily_day';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  int _todayCount(DateTime now) =>
      _prefs.getString(_kDay) == _dayKey(now) ? (_prefs.getInt(_kCount) ?? 0) : 0;

  bool canShowInterstitial(AdRules rules) {
    final now = _clock();
    if (_todayCount(now) >= rules.interstitialDailyCap) return false;
    final last = _prefs.getInt(_kLastShown);
    if (last != null) {
      final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(last));
      // 時計が巻き戻された場合（elapsed が負）は表示しない。
      if (elapsed < rules.interstitialMinInterval) return false;
    }
    return true;
  }

  Future<void> recordInterstitialShown() async {
    final now = _clock();
    await _prefs.setInt(_kCount, _todayCount(now) + 1);
    await _prefs.setString(_kDay, _dayKey(now));
    await _prefs.setInt(_kLastShown, now.millisecondsSinceEpoch);
  }
}
