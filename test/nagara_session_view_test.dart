import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<NagaraQuestion> _qs([int n = 3]) => [
      for (var i = 1; i <= n; i++)
        NagaraQuestion(
          id: 'q$i',
          prompt: 'もんだい$i',
          choices: const ['こたえA', 'こたえB', 'こたえC'],
          correctIndex: 0,
          explanation: 'かいせつ$i',
        ),
    ];

Future<(ProviderContainer, FakeSpeechBackend)> _container() async {
  final fake = FakeSpeechBackend();
  final c = ProviderContainer(overrides: [
    speechBackendProvider.overrideWithValue(fake),
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
  ]);
  await c.read(handsFreeProvider.notifier).update(
        const HandsFreeSettings(enabled: true, thinkSeconds: 5, betweenSeconds: 2),
      );
  return (c, fake);
}

Widget _app(
  ProviderContainer c, {
  List<NagaraQuestion>? questions,
  int? maxQuestions,
  void Function(NagaraQuestion, int)? onWrongAnswer,
  void Function(NagaraSessionState)? onFinished,
  VoidCallback? onClose,
  KitStrings? strings,
}) {
  final view = NagaraSessionView(
    questions: questions ?? _qs(),
    maxQuestions: maxQuestions,
    onWrongAnswer: onWrongAnswer,
    onFinished: onFinished,
    onClose: onClose,
  );
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      home: Scaffold(
        body: strings == null ? view : KitStringsScope(strings: strings, child: view),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester, [Duration d = Duration.zero]) async {
  await tester.pump(d);
  await tester.pump();
}

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  await tester.pump(const Duration(seconds: 60));
}

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('問題・進行状況・残り問数を出し、問題と選択肢を読み上げる', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    expect(find.text('問題 1 / 3'), findsOneWidget);
    expect(find.text('残り 3 問'), findsOneWidget);
    expect(find.text('もんだい1'), findsOneWidget);
    expect(find.text('こたえB'), findsOneWidget);
    expect(find.text('考える時間です'), findsOneWidget);
    expect(find.text('選択肢をタップして答えることもできます。'), findsOneWidget);
    expect(fake.spoken.single, contains('もんだい1'));
    await _leave(tester);
  });

  testWidgets('一時停止・スキップ・終了のボタンは 72pt 以上', (tester) async {
    bigScreen(tester);
    final (c, _) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    for (final label in ['一時停止', 'スキップ', '終了']) {
      final size = tester.getSize(find.widgetWithText(FilledButton, label));
      expect(size.height, greaterThanOrEqualTo(72), reason: label);
      expect(size.width, greaterThanOrEqualTo(72), reason: label);
    }
    await _leave(tester);
  });

  testWidgets('一時停止すると進まず、再開で続きに戻る', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    await tester.tap(find.text('一時停止'));
    await _settle(tester);
    expect(find.text('一時停止中です'), findsOneWidget);
    expect(find.text('再開'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'スキップ')).onPressed, isNull);
    final spoken = fake.spoken.length;
    await _settle(tester, const Duration(seconds: 30));
    expect(find.text('問題 1 / 3'), findsOneWidget);
    expect(fake.spoken.length, spoken);
    await tester.tap(find.text('再開'));
    await _settle(tester);
    expect(find.text('考える時間です'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('放っておくと、考える間のあとに答えを読み、間を置いて次の問題へ進む', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    await _settle(tester, const Duration(seconds: 5));
    expect(find.text('次の問題の前のひと息です'), findsOneWidget);
    expect(fake.spoken.last, contains('正解はア、こたえAです'));
    expect(find.text('かいせつ1'), findsOneWidget);
    await _settle(tester, const Duration(seconds: 2));
    expect(find.text('問題 2 / 3'), findsOneWidget);
    expect(find.text('残り 2 問'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('タップで誤答すると onWrongAnswer に返り、責めない言い方で正解を読む', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    final wrong = <(String, int)>[];
    await tester.pumpWidget(_app(c, onWrongAnswer: (q, i) => wrong.add((q.id, i))));
    await _settle(tester);
    await tester.tap(find.text('こたえB'));
    await _settle(tester);
    expect(wrong, [('q1', 1)]);
    expect(find.text('えらんだ答え'), findsOneWidget);
    expect(find.text('不正解'), findsNothing);
    expect(fake.spoken.last, contains(NagaraStrings.ja.checkSpoken));
    expect(fake.spoken.last, contains('正解はア'));
    await _settle(tester, const Duration(seconds: 2));
    expect(find.text('問題 2 / 3'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('正解のタップは誤答として返さず、正解を読む', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    final wrong = <(String, int)>[];
    await tester.pumpWidget(_app(c, onWrongAnswer: (q, i) => wrong.add((q.id, i))));
    await _settle(tester);
    await tester.tap(find.text('こたえA'));
    await _settle(tester);
    expect(wrong, isEmpty);
    expect(fake.spoken.last, startsWith(NagaraStrings.ja.correctSpoken));
    await _leave(tester);
  });

  testWidgets('画面を離れると読み上げを止め、その後は何も読まない', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    final stops = fake.stopCount;
    final spoken = fake.spoken.length;
    await _leave(tester);
    expect(fake.stopCount, greaterThan(stops));
    expect(fake.spoken.length, spoken);
  });

  testWidgets('終了すると結果を出し、とじるボタン（72pt 以上）で onClose', (tester) async {
    bigScreen(tester);
    final (c, _) = await _container();
    addTearDown(c.dispose);
    var closed = false;
    NagaraSessionState? summary;
    await tester.pumpWidget(_app(
      c,
      questions: _qs(1),
      onClose: () => closed = true,
      onFinished: (s) => summary = s,
    ));
    await _settle(tester);
    await tester.tap(find.text('こたえA'));
    await _settle(tester);
    expect(find.text('おつかれさまでした'), findsOneWidget);
    expect(find.text('1 問のうち 1 問、正解でした。'), findsOneWidget);
    expect(summary?.finishReason, NagaraFinishReason.completed);
    final size = tester.getSize(find.widgetWithText(FilledButton, 'とじる'));
    expect(size.height, greaterThanOrEqualTo(72));
    await tester.tap(find.text('とじる'));
    expect(closed, isTrue);
    await _leave(tester);
  });

  testWidgets('上限問数に達すると、休憩を促す文言を出す', (tester) async {
    bigScreen(tester);
    final (c, _) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c, questions: _qs(4), maxQuestions: 1));
    await _settle(tester);
    expect(find.text('残り 1 問'), findsOneWidget);
    await tester.tap(find.text('スキップ'));
    await _settle(tester);
    expect(find.text(NagaraStrings.ja.restSuggestion), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('終了ボタンで止まり、英語の文言にも切り替わる', (tester) async {
    bigScreen(tester);
    final (c, _) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c, strings: KitStrings.en));
    await _settle(tester);
    expect(find.text('Question 1 / 3'), findsOneWidget);
    expect(find.text('3 left'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('End'));
    await _settle(tester);
    expect(find.text('Nice work today'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('音声が使えないときは、画面だけで進める旨を出す', (tester) async {
    bigScreen(tester);
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    fake.error = StateError('no tts');
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    expect(find.text('音声が使えないため、画面だけで進めています。'), findsOneWidget);
    expect(find.text('考える時間です'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('動きを減らす設定でも表示され、読み上げ状態に Semantics がある', (tester) async {
    bigScreen(tester);
    final handle = tester.ensureSemantics();
    final (c, _) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _app(c),
    ));
    await _settle(tester);
    expect(find.bySemanticsLabel(RegExp('問題 1 / 3')), findsOneWidget);
    expect(find.text('考える時間です'), findsOneWidget);
    await _leave(tester);
    handle.dispose();
  });
}
