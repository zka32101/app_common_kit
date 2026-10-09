import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {KitStrings? strings}) => MaterialApp(
  home: Scaffold(
    body: strings == null
        ? child
        : KitStringsScope(strings: strings, child: child),
  ),
);

void main() {
  testWidgets('Scope が無ければ日本語（端末が英語でも変わらない）', (tester) async {
    await tester.pumpWidget(_wrap(const StreakBadge(days: 3)));
    expect(find.text('3日連続'), findsOneWidget);
  });

  testWidgets('Scope で英語に切り替わる', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            const StreakBadge(days: 3),
            const StreakBadge(days: 0),
            ErrorState(onRetry: () {}),
            const ResultSummary(correct: 8, total: 10, passRatio: 0.7),
          ],
        ),
        strings: KitStrings.en,
      ),
    );
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('Start today'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('8 of 10 correct'), findsOneWidget);
    expect(find.text('Passing line 70%'), findsOneWidget);
  });

  testWidgets('引数で渡した文言は Scope より優先される', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StreakBadge(days: 0, zeroText: 'Go!'),
        strings: KitStrings.en,
      ),
    );
    expect(find.text('Go!'), findsOneWidget);
  });

  test('forLocale と全イベントの表示名', () {
    expect(KitStrings.forLocale(const Locale('en', 'US')), same(KitStrings.en));
    expect(KitStrings.forLocale(const Locale('fr')), same(KitStrings.ja));
    for (final t in CoinEventType.values) {
      expect(
        KitStrings.en.coinEventLabels.containsKey(t.name),
        isTrue,
        reason: t.name,
      );
      expect(
        KitStrings.ja.coinEventLabels.containsKey(t.name),
        isTrue,
        reason: t.name,
      );
    }
    expect(coinEventLabel(CoinEventType.streak, KitStrings.en), 'Study streak');
    expect(coinEventLabel(CoinEventType.streak), '連続学習');
  });

  testWidgets('FeedbackFormPage が英語で出る。引数 strings は Scope より優先', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const FeedbackFormPage(appName: 'test', strings: KitStrings.en),
        ),
      ),
    );
    expect(find.text('Feedback & bug reports'), findsOneWidget);
    expect(find.text('Bug report'), findsOneWidget);
    expect(find.text('Feature request'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('不具合報告'), findsNothing);
  });

  testWidgets('FeedbackFormPage は Scope が無ければ日本語', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const FeedbackFormPage(appName: 'test')),
      ),
    );
    expect(find.text('ご意見・不具合報告'), findsOneWidget);
    expect(find.text('送信する'), findsOneWidget);
  });

  test('ja/en の文言関数', () {
    expect(
      KitStrings.en.passAskTitle('IT Passport'),
      'Tell us your IT Passport result',
    );
    expect(KitStrings.ja.passAskTitle('ITパスポート'), 'ITパスポートの結果を教えてください');
    expect(KitStrings.en.passCoin(30), 'Study coins +30');
    expect(KitStrings.ja.passOutfit('帽子'), '「帽子」を着られるようになりました');
  });

  testWidgets('選択肢・解説・読み上げ・下部タブが ja/en で切り替わる', (tester) async {
    Widget body() => Column(children: [
          ChoiceTile(label: 'A', text: 'x', state: ChoiceState.correct),
          ChoiceTile(label: 'B', text: 'y', state: ChoiceState.incorrect),
          const ExplanationPanel(body: 'b', sourceRef: 'Act 1', checkedAt: '2026-10-09'),
          ReadAloudButton(onPressed: () {}),
        ]);
    await tester.pumpWidget(_wrap(body()));
    expect(find.text('正解'), findsOneWidget);
    expect(find.text('不正解'), findsOneWidget);
    expect(find.text('解説'), findsOneWidget);
    expect(find.text('出典: Act 1（2026-10-09 確認）'), findsOneWidget);
    expect(find.byTooltip('読み上げ'), findsOneWidget);

    await tester.pumpWidget(_wrap(body(), strings: KitStrings.en));
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);
    expect(find.text('Source: Act 1 (checked 2026-10-09)'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

  testWidgets('UkalabShell の下部タブ。labels を渡せば優先', (tester) async {
    final pages = [for (var i = 0; i < 5; i++) Text('p$i')];
    await tester.pumpWidget(MaterialApp(
      home: KitStringsScope(strings: KitStrings.en, child: UkalabShell(pages: pages)),
    ));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: UkalabShell(pages: pages)));
    expect(find.text('ホーム'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
      home: KitStringsScope(
        strings: KitStrings.en,
        child: UkalabShell(pages: pages, labels: const ['a', 'b', 'c', 'd', 'e']),
      ),
    ));
    expect(find.text('a'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
