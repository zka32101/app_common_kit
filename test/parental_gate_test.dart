import 'dart:math' as math;

import 'package:app_common_kit/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('問題: 答えは常に正の数で、数は10〜30', () {
    final r = math.Random(1);
    for (var i = 0; i < 500; i++) {
      final q = ParentalGateQuestion.random(r);
      expect(q.answer, greaterThan(0));
      expect(q.a, inInclusiveRange(10, 30));
      expect(q.b, inInclusiveRange(10, 30));
      if (!q.isAddition) expect(q.a, greaterThan(q.b));
    }
  });

  test('文言: 5言語が空でなく、読み上げ用のひな形に数の穴がある', () {
    for (final c in ['ja', 'en', 'zh', 'zh-Hant', 'ko', 'xx']) {
      final s = ParentalGateStrings.forCode(c);
      for (final t in [s.title, s.description, s.hint, s.wrong, s.ok, s.cancel]) {
        expect(t, isNotEmpty);
      }
      expect(s.questionLabel, allOf(contains('{a}'), contains('{b}')));
    }
    expect(ParentalGateStrings.forCode('en').ok, 'Next');
  });

  // 乱数を固定して、出る問題を知る。
  ParentalGateQuestion peek(int seed) => ParentalGateQuestion.random(math.Random(seed));

  testWidgets('正解すると true', (tester) async {
    final q = peek(7);
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await requireParentalGate(context, random: math.Random(7)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('${q.a} ${q.operator} ${q.b} = ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '${q.answer}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('まちがえると答えが消えて、エラーを出す。上限で false を返して閉じる', (tester) async {
    final q = peek(7);
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await requireParentalGate(context, random: math.Random(7), maxAttempts: 2),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '${q.answer + 1}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(find.text('答えが違います'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(result, isNull, reason: 'まだ閉じない');

    await tester.enterText(find.byType(TextField), '${q.answer + 2}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.byType(ParentalGateDialog), findsNothing);
  });

  testWidgets('上限の手前で正解すれば通れる', (tester) async {
    final q = peek(3);
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await requireParentalGate(context, random: math.Random(3)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '${q.answer + 1}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '${q.answer}');
    await tester.tap(find.text('つぎへ'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('キャンセルすると false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await requireParentalGate(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('英語の文言で出せる。読み上げ用のラベルがある', (tester) async {
    final q = peek(7);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => requireParentalGate(context,
                strings: ParentalGateStrings.en, random: math.Random(7)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('For parents'), findsOneWidget);
    expect(find.bySemanticsLabel('${q.a} ${q.isAddition ? '+' : '−'} ${q.b}?'), findsOneWidget);
  });

  testWidgets('parentalGateBeforePurchase: ゲートを通らなければ購入しない／画面が無ければ false', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final hook = parentalGateBeforePurchase(key);
    expect(await hook('p1'), isFalse, reason: 'Navigator が無い');

    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold(body: SizedBox())));
    bool? result;
    final future = hook('p1').then((v) => result = v);
    await tester.pumpAndSettle();
    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();
    await future;
    expect(result, isFalse);
  });
}
