import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {double scale = 1.0, Brightness b = Brightness.light}) {
  final theme = b == Brightness.light
      ? UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei)
      : UkalabTheme.dark(field: UkalabField.ai, cert: UkalabCert.gKentei);
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

  group('StreakBadge', () {
    testWidgets('0日でも責めない文言、1日以上は日数', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        StreakBadge(days: 0),
        StreakBadge(days: 7),
      ])));
      expect(find.text('今日から始めよう'), findsOneWidget);
      expect(find.text('7日連続'), findsOneWidget);
    });
  });

  group('ExplanationPanel', () {
    testWidgets('出典があれば確認日つきで出る。なければ出ない', (tester) async {
      await tester.pumpWidget(_app(const Column(children: [
        ExplanationPanel(body: '本文', sourceRef: '道路交通法第34条', checkedAt: '2026-10-02'),
        ExplanationPanel(body: '出典なし'),
      ])));
      expect(find.text('出典: 道路交通法第34条（2026-10-02 確認）'), findsOneWidget);
      expect(find.textContaining('出典:'), findsOneWidget);
    });
  });

  group('ResultSummary', () {
    testWidgets('合格ライン到達と未到達で文言が変わる（アイコンも併用）', (tester) async {
      await tester.pumpWidget(_app(const ResultSummary(correct: 8, total: 10, passRatio: 0.7)));
      expect(find.text('合格ライン到達'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('8 / 10 問正解'), findsOneWidget);

      await tester.pumpWidget(_app(const ResultSummary(correct: 5, total: 10, passRatio: 0.7)));
      expect(find.text('あと少し。弱点を復習しよう'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('問題数0でも落ちない', (tester) async {
      await tester.pumpWidget(_app(const ResultSummary(correct: 0, total: 0)));
      expect(find.text('0%'), findsOneWidget);
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

  group('UkalabShell', () {
    testWidgets('下部タブは5つで、押すと画面が切り替わる', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: UkalabTheme.light(field: UkalabField.it),
        home: UkalabShell(pages: [for (final n in ['H', 'M', 'E', 'R', 'S']) Text('page-$n')]),
      ));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      for (final l in UkalabShell.defaultLabels) {
        expect(find.text(l), findsOneWidget);
      }
      await tester.tap(find.text('設定'));
      await tester.pump();
      expect(find.text('page-S'), findsOneWidget);
    });
  });

  group('文字拡大 200%・ダーク', () {
    for (final b in Brightness.values) {
      testWidgets('全部品が例外なく表示される (${b.name})', (tester) async {
        await tester.pumpWidget(_app(
          Column(children: [
            const QuestionCard(
              index: 3,
              total: 10,
              text: '次のうち、生成AIの説明として最も適切なものはどれか。長い問題文でも折り返して読めること。',
              child: Column(children: [
                ChoiceTile(label: 'A', text: '長い選択肢の文章が二行三行にわたっても崩れないことを確認します', state: ChoiceState.correct),
                SizedBox(height: 8),
                ChoiceTile(label: 'B', text: '選択肢B', state: ChoiceState.incorrect),
                SizedBox(height: 8),
                ChoiceTile(label: 'C', text: '選択肢C', state: ChoiceState.selected),
              ]),
            ),
            ExplanationPanel(body: '解説の文章です。' * 8, sourceRef: '教則 第8章', checkedAt: '2026-10-02'),
            const Row(children: [ProgressRing(value: 0.6, label: '習得度'), StreakBadge(days: 12)]),
            const ResultSummary(correct: 7, total: 10, passRatio: 0.7),
          ]),
          scale: 2.0,
          b: b,
        ));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
