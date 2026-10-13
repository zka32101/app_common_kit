import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('未回答は「同意なし」。尋ねる必要がある', () async {
    final c = ConsentController();
    await c.load();
    expect(c.allows(ConsentCategory.analytics), isFalse);
    expect(c.needsPrompt, isTrue);
    expect(c.nonPersonalizedAds, isTrue);
  });

  test('回答は保存され、次の起動で読める', () async {
    final a = ConsentController(store: SharedPreferencesConsentStore('app'));
    await a.load();
    await a.set(ConsentCategory.analytics, true);
    await a.set(ConsentCategory.crashReports, false);

    final b = ConsentController(store: SharedPreferencesConsentStore('app'));
    await b.load();
    expect(b.allows(ConsentCategory.analytics), isTrue);
    expect(b.allows(ConsentCategory.crashReports), isFalse);
    expect(b.isUnanswered(ConsentCategory.personalizedAds), isTrue);
    expect(b.needsPrompt, isTrue);
  });

  test('アプリごとに保存先が分かれる', () async {
    final a = ConsentController(store: SharedPreferencesConsentStore('one'));
    await a.load();
    await a.setAll(true);
    final b = ConsentController(store: SharedPreferencesConsentStore('two'));
    await b.load();
    expect(b.allows(ConsentCategory.analytics), isFalse);
  });

  test('対象外の項目は、常に「同意なし」で、書き込めない（子ども向けは広告を入れない）', () async {
    final c = ConsentController(categories: const [ConsentCategory.crashReports]);
    await c.load();
    await c.setAll(true);
    expect(c.allows(ConsentCategory.crashReports), isTrue);
    expect(c.allows(ConsentCategory.personalizedAds), isFalse);
    await c.set(ConsentCategory.personalizedAds, true);
    expect(c.allows(ConsentCategory.personalizedAds), isFalse);
    expect(c.nonPersonalizedAds, isTrue);
    expect(c.needsPrompt, isFalse);
  });

  test('reset で未回答に戻る', () async {
    final c = ConsentController(store: SharedPreferencesConsentStore('app'));
    await c.load();
    await c.setAll(true);
    await c.reset();
    expect(c.allows(ConsentCategory.analytics), isFalse);
    expect(c.needsPrompt, isTrue);
    final d = ConsentController(store: SharedPreferencesConsentStore('app'));
    await d.load();
    expect(d.needsPrompt, isTrue);
  });

  test('ConsentBinder: 同意に合わせて送り先を付け外しする', () async {
    final consent = ConsentController();
    await consent.load();
    final analytics = Analytics(null);
    final crash = CrashReporter(null);
    final ab = FakeAnalyticsBackend();
    final cb = FakeCrashBackend();
    final binder = ConsentBinder(consent,
        analytics: analytics, analyticsBackend: ab, crashReporter: crash, crashBackend: cb);

    expect(analytics.backend, isNull);
    expect(await analytics.log('study_start'), isFalse);

    await consent.set(ConsentCategory.analytics, true);
    expect(analytics.backend, same(ab));
    expect(crash.backend, isNull);
    expect(await analytics.log('study_start'), isTrue);

    await consent.set(ConsentCategory.analytics, false);
    expect(analytics.backend, isNull);

    await consent.setAll(true);
    expect(crash.backend, same(cb));

    binder.dispose();
    await consent.setAll(false);
    expect(crash.backend, same(cb), reason: 'dispose 後は追従しない');
  });

  test('adConfigWithConsent: 同意が無ければ非パーソナライズ。元が非パーソナライズなら維持', () async {
    const base = AdConfig(
        unitIds: AdUnitIds(banner: 'b', interstitial: 'i', rewarded: 'r'), childDirected: true);
    final c = ConsentController();
    await c.load();
    expect(adConfigWithConsent(base, c).nonPersonalizedAds, isTrue);
    expect(adConfigWithConsent(base, c).childDirected, isTrue);
    await c.set(ConsentCategory.personalizedAds, true);
    expect(adConfigWithConsent(base, c).nonPersonalizedAds, isFalse);

    const strict = AdConfig(
        unitIds: AdUnitIds(banner: 'b', interstitial: 'i', rewarded: 'r'), nonPersonalizedAds: true);
    expect(adConfigWithConsent(strict, c).nonPersonalizedAds, isTrue);
  });

  test('文言: 5言語が空でなく、言語コードで選べる', () {
    for (final code in ['ja', 'en', 'zh', 'zh-Hant', 'ko', 'xx']) {
      final s = ConsentStrings.forCode(code);
      for (final cat in ConsentCategory.values) {
        expect(s.titleOf(cat), isNotEmpty);
        expect(s.bodyOf(cat), isNotEmpty);
      }
      for (final t in [s.menu, s.promptTitle, s.promptBody, s.acceptAll, s.declineAll, s.customize, s.close]) {
        expect(t, isNotEmpty);
      }
    }
    expect(ConsentStrings.forCode('en').acceptAll, 'Agree to all');
    expect(ConsentStrings.forCode('xx').menu, ConsentStrings.ja.menu);
  });

  Future<void> open(WidgetTester tester, ConsentController c) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showConsentPrompt(context, c, strings: ConsentStrings.ja),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('初回の案内: すべて同意', (tester) async {
    final c = ConsentController();
    await c.load();
    await open(tester, c);
    await tester.tap(find.text('すべて同意する'));
    await tester.pumpAndSettle();
    expect(ConsentCategory.values.every(c.allows), isTrue);
    expect(c.needsPrompt, isFalse);
  });

  testWidgets('初回の案内: 同意しない（回答として保存し、再度は尋ねない）', (tester) async {
    final c = ConsentController();
    await c.load();
    await open(tester, c);
    await tester.tap(find.text('同意しない'));
    await tester.pumpAndSettle();
    expect(ConsentCategory.values.any(c.allows), isFalse);
    expect(c.needsPrompt, isFalse);
  });

  testWidgets('初回の案内: 項目ごとに選ぶ。触らない項目は「同意しない」で確定', (tester) async {
    final c = ConsentController();
    await c.load();
    await open(tester, c);
    await tester.tap(find.text('項目ごとに選ぶ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, '利用状況の分析'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(c.allows(ConsentCategory.analytics), isTrue);
    expect(c.allows(ConsentCategory.crashReports), isFalse);
    expect(c.needsPrompt, isFalse);
  });

  testWidgets('案内は、尋ねる必要が無ければ出ない', (tester) async {
    final c = ConsentController(categories: const []);
    await c.load();
    await open(tester, c);
    expect(find.text('データの利用について'), findsNothing);
  });

  testWidgets('設定画面: consent を渡すと「プライバシーの設定」が出て、スイッチで変えられる', (tester) async {
    final c = ConsentController();
    await c.load();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: SettingsScreen(
          appName: 'test',
          consent: c,
          showPurchase: false,
          showTheme: false,
          showHandsFree: false,
          showFeedback: false,
        ),
      ),
    ));
    await tester.tap(find.text('プライバシーの設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'エラーの送信'));
    await tester.pumpAndSettle();
    expect(c.allows(ConsentCategory.crashReports), isTrue);
  });
}
