import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {KitStrings? strings}) => MaterialApp(
      home: Scaffold(
        body: strings == null ? child : KitStringsScope(strings: strings, child: child),
      ),
    );

void main() {
  testWidgets('Scope が無ければ日本語（端末が英語でも変わらない）', (tester) async {
    await tester.pumpWidget(_wrap(const StreakBadge(days: 3)));
    expect(find.text('3日連続'), findsOneWidget);
  });

  testWidgets('Scope で英語に切り替わる', (tester) async {
    await tester.pumpWidget(_wrap(
      Column(children: [
        const StreakBadge(days: 3),
        const StreakBadge(days: 0),
        ErrorState(onRetry: () {}),
        const ResultSummary(correct: 8, total: 10, passRatio: 0.7),
      ]),
      strings: KitStrings.en,
    ));
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('Start today'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('8 of 10 correct'), findsOneWidget);
    expect(find.text('Passing line 70%'), findsOneWidget);
  });

  testWidgets('引数で渡した文言は Scope より優先される', (tester) async {
    await tester.pumpWidget(_wrap(const StreakBadge(days: 0, zeroText: 'Go!'), strings: KitStrings.en));
    expect(find.text('Go!'), findsOneWidget);
  });

  test('forLocale と全イベントの表示名', () {
    expect(KitStrings.forLocale(const Locale('en', 'US')), same(KitStrings.en));
    expect(KitStrings.forLocale(const Locale('fr')), same(KitStrings.ja));
    for (final t in CoinEventType.values) {
      expect(KitStrings.en.coinEventLabels.containsKey(t.name), isTrue, reason: t.name);
      expect(KitStrings.ja.coinEventLabels.containsKey(t.name), isTrue, reason: t.name);
    }
    expect(coinEventLabel(CoinEventType.streak, KitStrings.en), 'Study streak');
    expect(coinEventLabel(CoinEventType.streak), '連続学習');
  });
}
