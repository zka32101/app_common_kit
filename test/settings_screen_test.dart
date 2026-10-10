import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  KitStrings? strings,
  SettingsScreen? screen,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
    entitlementServiceProvider.overrideWithValue(FakeEntitlementService(
      availableOffers: const [
        EntitlementOffer(id: 'noads', productId: 'p', title: '広告非表示', priceString: '¥480'),
      ],
    )),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      builder: strings == null ? null : (c, child) => KitStringsScope(strings: strings, child: child!),
      home: screen ?? const SettingsScreen(appName: 'テスト', appVersion: '1.2.3'),
    ),
  ));
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appThemeMode.value = ThemeMode.system;
  });

  testWidgets('既定の項目: 購入・表示モード・片手・フィードバック・このアプリについて（日本語）', (tester) async {
    await _pump(tester);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('購入'), findsOneWidget);
    expect(find.text('表示モード'), findsOneWidget);
    expect(find.text('片手・ながら学習'), findsOneWidget);
    expect(find.text('ご意見・不具合報告'), findsOneWidget);
    expect(find.text('このアプリについて'), findsOneWidget);
    // 渡していない項目は出ない
    expect(find.text('受験日'), findsNothing);
    expect(find.text('言語'), findsNothing);
    expect(find.text('学習の引き継ぎ（機種変更）'), findsNothing);
  });

  testWidgets('項目は引数で出し分ける', (tester) async {
    await _pump(
      tester,
      screen: SettingsScreen(
        appName: 'テスト',
        showTheme: false,
        showHandsFree: false,
        showPurchase: false,
        showFeedback: false,
        examDate: DateTime(2026, 11, 22),
        onExamDateChanged: (_) {},
        onTransfer: () {},
        languages: const [SettingsLanguage('ja', '日本語'), SettingsLanguage('en', 'English')],
        languageCode: 'ja',
        onLanguageChanged: (_) {},
      ),
    );
    expect(find.text('受験日'), findsOneWidget);
    expect(find.text('2026/11/22'), findsOneWidget);
    expect(find.text('言語'), findsOneWidget);
    expect(find.text('学習の引き継ぎ（機種変更）'), findsOneWidget);
    expect(find.text('購入'), findsNothing);
    expect(find.text('表示モード'), findsNothing);
    expect(find.text('片手・ながら学習'), findsNothing);
    expect(find.text('ご意見・不具合報告'), findsNothing);
  });

  testWidgets('言語は2つ以上あるときだけ出る', (tester) async {
    await _pump(
      tester,
      screen: SettingsScreen(
        appName: 'テスト',
        languages: const [SettingsLanguage('ja', '日本語')],
        onLanguageChanged: (_) {},
      ),
    );
    expect(find.text('言語'), findsNothing);
  });

  testWidgets('表示モードを選ぶと appThemeMode が変わる', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('ダーク'));
    await tester.pump();
    expect(appThemeMode.value, ThemeMode.dark);
    await tester.tap(find.text('ライト'));
    await tester.pump();
    expect(appThemeMode.value, ThemeMode.light);
  });

  testWidgets('言語を選ぶと、そのコードで onLanguageChanged が呼ばれる', (tester) async {
    String? got;
    await _pump(
      tester,
      screen: SettingsScreen(
        appName: 'テスト',
        languages: const [SettingsLanguage('ja', '日本語'), SettingsLanguage('en', 'English')],
        languageCode: 'ja',
        onLanguageChanged: (c) => got = c,
      ),
    );
    await tester.tap(find.text('English'));
    expect(got, 'en');
  });

  testWidgets('片手モード: 有効にすると詳細が出て、設定が保存される', (tester) async {
    final c = await _pump(tester);
    expect(find.text('問題を読み上げる'), findsNothing);
    await tester.tap(find.text('片手モードを使う'));
    await tester.pump();
    expect(c.read(handsFreeProvider).enabled, isTrue);
    expect(find.text('問題を読み上げる'), findsOneWidget);
    expect(find.text('解説を読み上げる'), findsOneWidget);
    expect(find.text('読み上げの速さ'), findsOneWidget);

    await tester.tap(find.text('問題を読み上げる'));
    await tester.pump();
    expect(c.read(handsFreeProvider).speakQuestion, isFalse);
  });

  testWidgets('受験日を解除すると null で onExamDateChanged が呼ばれる', (tester) async {
    DateTime? got = DateTime(2000);
    await _pump(
      tester,
      screen: SettingsScreen(
        appName: 'テスト',
        showPurchase: false,
        examDate: DateTime(2026, 11, 22),
        onExamDateChanged: (d) => got = d,
      ),
    );
    await tester.tap(find.byIcon(Icons.clear));
    expect(got, isNull);
  });

  testWidgets('フィードバックの画面を開ける（同じ言語で）', (tester) async {
    await _pump(tester, strings: KitStrings.en);
    await tester.tap(find.text('Feedback & bug reports'));
    await tester.pumpAndSettle();
    expect(find.text('Bug report'), findsOneWidget);
  });

  testWidgets('このアプリについて: バージョンと免責を出す', (tester) async {
    await _pump(
      tester,
      screen: const SettingsScreen(appName: 'テスト', appVersion: '1.2.3', disclaimer: '非公式のアプリです。'),
    );
    await tester.tap(find.text('このアプリについて'));
    await tester.pumpAndSettle();
    expect(find.text('バージョン 1.2.3'), findsOneWidget);
    expect(find.text('非公式のアプリです。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('非公式のアプリです。'), findsNothing);
  });

  testWidgets('英語: 画面も、中の購入欄も英語になる。strings: を直接渡しても同じ', (tester) async {
    await _pump(tester, strings: KitStrings.en);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Purchases'), findsOneWidget); // PurchaseSection
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('購入'), findsNothing);

    // Scope なしで、strings: だけ渡しても、中の購入欄まで英語になる
    await _pump(tester, screen: const SettingsScreen(appName: 'x', strings: KitStrings.en));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Purchases'), findsOneWidget);
  });

  testWidgets('extraSections がこのアプリについての前に並ぶ', (tester) async {
    await _pump(
      tester,
      screen: const SettingsScreen(
        appName: 'テスト',
        extraSections: [SettingsSection(title: '独自の項目', children: [Text('中身')])],
      ),
    );
    expect(find.text('独自の項目'), findsOneWidget);
    expect(find.text('中身'), findsOneWidget);
  });

  testWidgets('片手モードを有効にした状態でも、タップ領域・読み上げラベルの基準を満たす', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(find.text('片手モードを使う'));
    await tester.pump();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
