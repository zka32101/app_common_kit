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
    await tester.pumpWidget(_wrap(ErrorState(onRetry: () {})));
    expect(find.text('もう一度試す'), findsOneWidget);
  });

  testWidgets('Scope で英語に切り替わる', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            ErrorState(onRetry: () {}),
          ],
        ),
        strings: KitStrings.en,
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  test('forLocale と全イベントの表示名', () {
    expect(KitStrings.forLocale(const Locale('en', 'US')), same(KitStrings.en));
    expect(KitStrings.forLocale(const Locale('fr')), same(KitStrings.ja));
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

  testWidgets('選択肢・読み上げが ja/en で切り替わる', (tester) async {
    Widget body() => Column(children: [
          ChoiceTile(label: 'A', text: 'x', state: ChoiceState.correct),
          ChoiceTile(label: 'B', text: 'y', state: ChoiceState.incorrect),
          ReadAloudButton(onPressed: () {}),
        ]);
    await tester.pumpWidget(_wrap(body()));
    expect(find.text('正解'), findsOneWidget);
    expect(find.text('不正解'), findsOneWidget);
    expect(find.byTooltip('読み上げ'), findsOneWidget);

    await tester.pumpWidget(_wrap(body(), strings: KitStrings.en));
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Incorrect'), findsOneWidget);
    expect(find.byTooltip('Read aloud'), findsOneWidget);
  });

}

