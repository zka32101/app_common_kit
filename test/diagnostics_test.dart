import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('scrubText: メール・トークン・電話番号を伏せ、長さを切る', () {
    expect(scrubText('a@b.com 090-1234-5678 ${'x' * 40}'), '[email] [number] [token]');
    expect(scrubText('あ' * 500).length, 300);
    expect(scrubText('あ' * 500, maxLength: 10).length, 10);
  });

  test('CrashReporter.scrub は scrubText と同じ規則（挙動は変わらない）', () {
    expect(CrashReporter.scrub('t=${'a' * 40}'), 't=[token]');
    expect(CrashReporter.scrub('あ' * 500).length, CrashReporter.maxLogLength);
  });

  test('DiagnosticLog: 古い順に並び、容量を超えたら古いものから捨て、内容を整形する', () {
    var now = DateTime(2026, 1, 1, 9, 5, 7);
    final log = DiagnosticLog(capacity: 2, clock: () => now);
    expect(log.isEmpty, isTrue);
    log.add('一つ目 a@b.com');
    now = now.add(const Duration(seconds: 3));
    log.add('二つ目');
    now = now.add(const Duration(seconds: 3));
    log.add('三つ目');
    expect(log.lines(), ['09:05:10 二つ目', '09:05:13 三つ目']);
    log.clear();
    expect(log.isEmpty, isTrue);
    log.add('x a@b.com');
    expect(log.lines().single, endsWith('x [email]'));
  });

  test('CrashReporter.log は、送り先が無くても診断用の記録に残す（端末内だけ）', () async {
    final log = DiagnosticLog();
    final r = CrashReporter(null, diagnosticLog: log);
    await r.log('画面を開いた');
    expect(log.lines().single, endsWith('画面を開いた'));
    // 送り先があれば、そちらにも送る
    final fake = FakeCrashBackend();
    final r2 = CrashReporter(fake, diagnosticLog: log);
    await r2.log('購入した');
    expect(fake.logs.single, '購入した');
    expect(log.lines().length, 2);
  });

  DiagnosticsCollector collector({DiagnosticLog? log, int maxLength = 3000, Map<String, String> extra = const {}}) =>
      DiagnosticsCollector(
        appName: 'myapp',
        appVersion: '1.2.3',
        extra: extra,
        log: log,
        maxLength: maxLength,
        platformInfo: () => 'android 14',
        localeInfo: () => 'ja-JP',
      );

  test('collect: 版・端末・言語・補足・記録が入る。利用者の識別子は無い', () {
    final log = DiagnosticLog(clock: () => DateTime(2026, 1, 1, 10));
    log.add('開いた');
    final t = collector(log: log, extra: {'購入': 'プレミアム'}).collect();
    expect(t, contains('app: myapp'));
    expect(t, contains('version: 1.2.3'));
    expect(t, contains('platform: android 14'));
    expect(t, contains('locale: ja-JP'));
    expect(t, contains('購入: プレミアム'));
    expect(t, contains('recent:\n10:00:00 開いた'));
    expect(t.toLowerCase(), isNot(contains('userid')));
  });

  test('collect: 記録が無ければ recent は出ない', () {
    expect(collector().collect(), isNot(contains('recent')));
  });

  test('collect: 補足の中のメールや電話番号は伏せる', () {
    final t = collector(extra: {'連絡先': 'me@example.com 090-1234-5678'}).collect();
    expect(t, isNot(contains('me@example.com')));
    expect(t, contains('[email] [number]'));
  });

  test('collect: 長さの上限を守り、先頭の情報は残し、記録は新しいものを残す', () {
    final log = DiagnosticLog(capacity: 100, clock: () => DateTime(2026, 1, 1, 10));
    for (var i = 0; i < 100; i++) {
      log.add('操作$i');
    }
    final t = collector(log: log, maxLength: 300).collect();
    expect(t.length, lessThanOrEqualTo(300));
    expect(t, contains('version: 1.2.3'));
    expect(t, contains('操作99'));
    expect(t, isNot(contains('操作0\n')));
  });

  test('文言: 5言語が空でなく、言語コードで選べる', () {
    for (final c in ['ja', 'en', 'zh', 'zh-Hant', 'ko', 'xx']) {
      final s = DiagnosticsStrings.forCode(c);
      for (final t in [s.attach, s.attachHint, s.preview, s.close]) {
        expect(t, isNotEmpty);
      }
    }
    expect(DiagnosticsStrings.forCode('en').close, 'Close');
  });

  test('FeedbackReport: diagnostics が無ければ JSON に出ない（従来と同じ）。あれば往復できる', () {
    final base = FeedbackReport(
      id: '1',
      type: FeedbackType.bug,
      title: 't',
      description: 'd',
      appName: 'a',
      appVersion: '1',
      platform: 'iOS',
      createdAt: DateTime(2026, 1, 1),
    );
    expect(base.toJson().containsKey('diagnostics'), isFalse);
    final withDiag = base.copyWith(diagnostics: 'version: 1');
    expect(withDiag.toJson()['diagnostics'], 'version: 1');
    expect(FeedbackReport.fromJson(withDiag.toJson()).diagnostics, 'version: 1');
    expect(FeedbackReport.fromJson(base.toJson()).diagnostics, isNull);
  });

  Future<List<FeedbackReport>> sendFrom(WidgetTester tester, {String Function()? collect, bool uncheck = false}) async {
    // 縦に長い画面にして、下の方のボタンも作られるようにする（ListView は画面外を作らないため）。
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final sent = <FeedbackReport>[];
    final container = ProviderContainer();
    container.read(feedbackProvider.notifier).setSubmitHandler((r) async => sent.add(r));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: FeedbackFormPage(appName: 'test', strings: KitStrings.ja, collectDiagnostics: collect)),
    ));
    await tester.enterText(find.byType(TextFormField).at(0), '落ちます');
    await tester.enterText(find.byType(TextFormField).at(1), '開くと落ちます。何度も試しました。');
    if (uncheck) {
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('送信する'));
    await tester.tap(find.text('送信する'));
    await tester.pumpAndSettle();
    return sent;
  }

  testWidgets('フォーム: collectDiagnostics を渡さなければ、チェックは出ず、診断情報は付かない（従来どおり）', (tester) async {
    final sent = await sendFrom(tester);
    expect(find.text('診断情報を添える'), findsNothing);
    expect(sent.single.diagnostics, isNull);
  });

  testWidgets('フォーム: 渡すと既定でオン。送る内容に診断情報が付く', (tester) async {
    final sent = await sendFrom(tester, collect: () => 'version: 9');
    expect(sent.single.diagnostics, 'version: 9');
  });

  testWidgets('フォーム: チェックを外すと、診断情報は付かない', (tester) async {
    var called = 0;
    final sent = await sendFrom(tester, collect: () {
      called++;
      return 'version: 9';
    }, uncheck: true);
    expect(sent.single.diagnostics, isNull);
    expect(called, 0, reason: '外したときは、集めもしない');
  });

  testWidgets('フォーム: 送る内容を見るボタンで、診断情報を表示できる', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: FeedbackFormPage(appName: 'test', strings: KitStrings.ja, collectDiagnostics: () => 'version: 9')),
    ));
    await tester.ensureVisible(find.text('送る内容を見る'));
    await tester.tap(find.text('送る内容を見る'));
    await tester.pumpAndSettle();
    expect(find.text('version: 9'), findsOneWidget);
  });
}
