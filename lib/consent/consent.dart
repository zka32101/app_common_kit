import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/ad_rules.dart';
import '../analytics/analytics.dart';
import '../crash/crash_reporter.dart';

/// 同意を取る対象。アプリが使うものだけを [ConsentController.categories] に渡す。
enum ConsentCategory {
  /// 利用状況の分析（`Analytics`）。
  analytics,

  /// クラッシュ・エラーの収集（`CrashReporter`）。
  crashReports,

  /// 広告のパーソナライズ（`AdConfig.nonPersonalizedAds` の逆）。
  personalizedAds,
}

/// 同意の保存先。
abstract class ConsentStore {
  /// 保存済みの回答。未回答の対象は含まれない。
  Future<Map<ConsentCategory, bool>> load();

  Future<void> save(Map<ConsentCategory, bool> answers);

  /// 回答を消す（データ削除用）。
  Future<void> clear();
}

/// 端末内（`SharedPreferences`）に保存する。キーは `<keyPrefix><カテゴリ名>`。
class SharedPreferencesConsentStore implements ConsentStore {
  SharedPreferencesConsentStore(this.appId, {this.keyPrefix = 'kit_consent_'});

  final String appId;
  final String keyPrefix;

  String _key(ConsentCategory c) => '$keyPrefix${appId}_${c.name}';

  @override
  Future<Map<ConsentCategory, bool>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final c in ConsentCategory.values)
        if (p.getBool(_key(c)) != null) c: p.getBool(_key(c))!,
    };
  }

  @override
  Future<void> save(Map<ConsentCategory, bool> answers) async {
    final p = await SharedPreferences.getInstance();
    for (final e in answers.entries) {
      await p.setBool(_key(e.key), e.value);
    }
  }

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    for (final c in ConsentCategory.values) {
      await p.remove(_key(c));
    }
  }
}

/// テスト・プレビュー用。メモリ上だけ。
class InMemoryConsentStore implements ConsentStore {
  final Map<ConsentCategory, bool> _data = {};

  @override
  Future<Map<ConsentCategory, bool>> load() async => Map.of(_data);

  @override
  Future<void> save(Map<ConsentCategory, bool> answers) async => _data.addAll(answers);

  @override
  Future<void> clear() async => _data.clear();
}

/// 同意の状態を持つ。**未回答は「同意なし」**として扱う（安全側）。
///
/// - [categories] に無い対象は、常に「同意なし」（子ども向けアプリは `personalizedAds` を入れない、など）
/// - 回答は保存し、変更を通知する（設定画面から、あとで変えられる）
/// - 法域によって、同意が必要な範囲は違う。何に同意を取るかは、専門家の確認を経て決める
class ConsentController extends ChangeNotifier {
  ConsentController({
    ConsentStore? store,
    this.categories = const [
      ConsentCategory.analytics,
      ConsentCategory.crashReports,
      ConsentCategory.personalizedAds,
    ],
  }) : _store = store ?? InMemoryConsentStore();

  final ConsentStore _store;

  /// このアプリが同意を取る対象。
  final List<ConsentCategory> categories;

  final Map<ConsentCategory, bool> _answers = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 起動時に一度呼ぶ。
  Future<void> load() async {
    _answers
      ..clear()
      ..addAll(await _store.load());
    _loaded = true;
    notifyListeners();
  }

  /// この対象を、まだ尋ねていないか。
  bool isUnanswered(ConsentCategory c) => categories.contains(c) && !_answers.containsKey(c);

  /// 取るべき同意が、1つでも未回答か（初回の案内を出すかの判断に使う）。
  bool get needsPrompt => categories.any(isUnanswered);

  /// 同意しているか。対象外・未回答は false。
  bool allows(ConsentCategory c) => categories.contains(c) && (_answers[c] ?? false);

  Future<void> set(ConsentCategory c, bool value) async {
    if (!categories.contains(c)) return;
    _answers[c] = value;
    await _store.save({c: value});
    notifyListeners();
  }

  /// すべての対象に、まとめて答える（「すべて同意」「すべて同意しない」）。
  Future<void> setAll(bool value) async {
    final next = {for (final c in categories) c: value};
    _answers.addAll(next);
    await _store.save(next);
    notifyListeners();
  }

  /// 回答を消して、未回答に戻す。
  Future<void> reset() async {
    _answers.clear();
    await _store.clear();
    notifyListeners();
  }

  /// 広告のパーソナライズに同意していなければ、非パーソナライズ広告にする。
  /// `AdConfig(nonPersonalizedAds: consent.nonPersonalizedAds, ...)` に渡す。
  bool get nonPersonalizedAds => !allows(ConsentCategory.personalizedAds);
}

/// 同意に合わせて、分析・クラッシュ収集の送り先を付けたり外したりする。
///
/// 同意が無い間は `backend` を null にする（何も送らない）。同意が変わると、すぐ反映する。
/// 使い終わったら [dispose] を呼ぶ。
class ConsentBinder {
  ConsentBinder(
    this.consent, {
    this.analytics,
    this.analyticsBackend,
    this.crashReporter,
    this.crashBackend,
  }) {
    consent.addListener(apply);
    apply();
  }

  final ConsentController consent;
  final Analytics? analytics;
  final AnalyticsBackend? analyticsBackend;
  final CrashReporter? crashReporter;
  final CrashBackend? crashBackend;

  /// 現在の同意を反映する（リスナーから呼ばれる）。
  void apply() {
    analytics?.backend = consent.allows(ConsentCategory.analytics) ? analyticsBackend : null;
    crashReporter?.backend = consent.allows(ConsentCategory.crashReports) ? crashBackend : null;
  }

  void dispose() => consent.removeListener(apply);
}

/// 広告の設定に、同意を反映した値を返す。
AdConfig adConfigWithConsent(AdConfig base, ConsentController consent) => AdConfig(
      unitIds: base.unitIds,
      rules: base.rules,
      childDirected: base.childDirected,
      maxAdContentRating: base.maxAdContentRating,
      nonPersonalizedAds: base.nonPersonalizedAds || consent.nonPersonalizedAds,
    );

/// アプリの `ProviderScope` で `consentProvider.overrideWithValue(consentController)` する。
/// 既定は、メモリ上だけの（保存しない）コントローラー。
final consentProvider = Provider<ConsentController>((ref) => ConsentController());
