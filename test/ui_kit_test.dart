import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {double scale = 1.0, Brightness b = Brightness.light}) {
  final theme = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: b);
  return MaterialApp(
    theme: theme,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: c!,
    ),
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  group('ChoiceTile', () {
    testWidgets('正解・不正解は色だけでなく ✓／✕ アイコンと文言で出る', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        ChoiceTile(label: 'A', text: '選択肢1', state: ChoiceState.correct),
        SizedBox(height: 8),
        ChoiceTile(label: 'B', text: '選択肢2', state: ChoiceState.incorrect),
      ])));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('正解'), findsOneWidget);
      expect(find.text('不正解'), findsOneWidget);
    });

    testWidgets('タップできて、高さは 44pt 以上', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(ChoiceTile(
          label: 'A', text: '短い', state: ChoiceState.idle, onTap: () => taps++)));
      expect(tester.getSize(find.byType(ChoiceTile)).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byType(ChoiceTile));
      expect(taps, 1);
    });

    testWidgets('選択中は selected として伝わる', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
          const ChoiceTile(label: 'A', text: '選択肢', state: ChoiceState.selected)));
      expect(
        tester.getSemantics(find.byType(ChoiceTile)),
        matchesSemantics(label: 'A。選択肢', isSelected: true, hasSelectedState: true),
      );
      handle.dispose();
    });
  });

  group('ProgressRing', () {
    testWidgets('割合を % で出し、範囲外・NaN は丸める', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        ProgressRing(value: 0.426),
        ProgressRing(value: 1.7),
        ProgressRing(value: -1),
        ProgressRing(value: double.nan),
      ])));
      expect(find.text('43%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(2));
    });
  });

  group('EmptyState / ErrorState', () {
    testWidgets('操作ボタンが押せる', (tester) async {
      var retried = false;
      await tester.pumpWidget(_app(SizedBox(height: 400, child: ErrorState(onRetry: () => retried = true))));
      await tester.tap(find.text('もう一度試す'));
      expect(retried, isTrue);

      await tester.pumpWidget(_app(const SizedBox(height: 400, child: EmptyState(message: 'まだ記録がありません。1問解いてみよう'))));
      expect(find.text('まだ記録がありません。1問解いてみよう'), findsOneWidget);
    });
  });

  group('文字拡大 200%・ダーク', () {
    for (final b in Brightness.values) {
      testWidgets('全部品が例外なく表示される (${b.name})', (tester) async {
        await tester.pumpWidget(_app(
          Column(children: [
            const Column(children: [
              ChoiceTile(label: 'A', text: '長い選択肢の文章が二行三行にわたっても崩れないことを確認します', state: ChoiceState.correct),
              SizedBox(height: 8),
              ChoiceTile(label: 'B', text: '選択肢B', state: ChoiceState.incorrect),
              SizedBox(height: 8),
              ChoiceTile(label: 'C', text: '選択肢C', state: ChoiceState.selected),
            ]),
            const ProgressRing(value: 0.6, label: '習得度'),
          ]),
          scale: 2.0,
          b: b,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  });
}

