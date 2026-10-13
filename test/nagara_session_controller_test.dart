import 'package:app_common_kit/app_common_kit.dart';
import 'package:fake_async/fake_async.dart';
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

class _PlainBackend implements SpeechBackend {
  final spoken = <String>[];
  @override
  Future<void> speak(String text, {double rate = 1.0}) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

class _Harness {
  _Harness({
    HandsFreeSettings s = const HandsFreeSettings(thinkSeconds: 5, betweenSeconds: 2),
    int n = 3,
    int? max,
    SpeechBackend? backend,
  })  : settings = s,
        fake = backend is FakeSpeechBackend ? backend : FakeSpeechBackend() {
    controller = NagaraSessionController(
      questions: _qs(n),
      backend: backend ?? fake,
      settings: () => settings,
      maxQuestions: max,
      onWrongAnswer: (q, i) => wrong.add((q.id, i)),
      onUnanswered: (q) => unanswered.add(q.id),
      onFinished: finished.add,
    );
  }

  HandsFreeSettings settings;
  final FakeSpeechBackend fake;
  late final NagaraSessionController controller;
  final wrong = <(String, int)>[];
  final unanswered = <String>[];
  final finished = <NagaraSessionState>[];
  NagaraPhase get phase => controller.state.phase;
}

void _tick(FakeAsync a, [int seconds = 0]) {
  a.elapse(Duration(seconds: seconds));
  a.flushMicrotasks();
}

void main() {
  test('問題を読む→考える間→答えを読む→間→次の問題、と自動で進み、最後に終わる', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.waitingAnswer);
      expect(h.fake.spoken.single, contains('もんだい1'));
      expect(h.fake.spoken.single, contains('こたえB'));

      _tick(a, 4);
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 1);
      expect(h.phase, NagaraPhase.pausedBetween);
      expect(h.fake.spoken[1], contains('正解はア、こたえAです'));
      expect(h.fake.spoken[1], contains('かいせつ1'));
      expect(h.unanswered, ['q1']);

      _tick(a, 1);
      expect(h.phase, NagaraPhase.pausedBetween);
      _tick(a, 1);
      expect(h.controller.state.index, 1);
      expect(h.phase, NagaraPhase.waitingAnswer);

      _tick(a, 5 + 2 + 5 + 2 + 5);
      expect(h.phase, NagaraPhase.finished);
      expect(h.controller.state.finishReason, NagaraFinishReason.completed);
      expect(h.controller.state.completed, 3);
      expect(h.controller.state.remaining, 0);
      expect(h.unanswered, ['q1', 'q2', 'q3']);
      expect(h.finished, hasLength(1));
      final spokenCount = h.fake.spoken.length;
      _tick(a, 60);
      expect(h.fake.spoken.length, spokenCount);
    });
  });

  test('読み上げが終わるまでは、考える間の時計を進めない（完了を待つ）', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.holdUntilReleased = true;
      h.controller.start();
      a.flushMicrotasks();
      _tick(a, 3);
      expect(h.phase, NagaraPhase.readingQuestion);
      h.fake.release();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 4);
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 1);
      expect(h.phase, NagaraPhase.readingAnswer);
      h.fake.release();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.pausedBetween);
    });
  });

  test('完了通知が来ない端末でも、目安の時間で先へ進む', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.holdUntilReleased = true;
      h.controller.start();
      a.flushMicrotasks();
      final limit = NagaraSessionController.estimateSpeechDuration(h.fake.spoken.single, 1.0) * 2 +
          const Duration(seconds: 5);
      a.elapse(limit - const Duration(milliseconds: 1));
      expect(h.phase, NagaraPhase.readingQuestion);
      a.elapse(const Duration(milliseconds: 2));
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.waitingAnswer);
      h.controller.dispose();
    });
  });

  test('読み終わりを待てない音声合成は、文字数からの目安の時間だけ待つ', () {
    fakeAsync((a) {
      final plain = _PlainBackend();
      final h = _Harness(backend: plain);
      h.controller.start();
      a.flushMicrotasks();
      final est = NagaraSessionController.estimateSpeechDuration(plain.spoken.single, 1.0);
      expect(h.phase, NagaraPhase.readingQuestion);
      a.elapse(est + const Duration(milliseconds: 1));
      expect(h.phase, NagaraPhase.waitingAnswer);
      h.controller.dispose();
    });
  });

  test('一時停止中は進まず、再開すると考える間を待ち直す', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      _tick(a, 3);
      h.controller.pause();
      expect(h.phase, NagaraPhase.paused);
      expect(h.controller.state.pausedFrom, NagaraPhase.waitingAnswer);
      final stops = h.fake.stopCount;
      expect(stops, greaterThan(0));
      _tick(a, 60);
      expect(h.phase, NagaraPhase.paused);
      expect(h.unanswered, isEmpty);

      h.controller.resume();
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 4);
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 1);
      expect(h.phase, NagaraPhase.pausedBetween);
      h.controller.dispose();
    });
  });

  test('問題を読んでいる最中に一時停止して再開すると、問題を読み直す', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.holdUntilReleased = true;
      h.controller.start();
      a.flushMicrotasks();
      h.controller.pause();
      a.flushMicrotasks();
      h.controller.resume();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.readingQuestion);
      expect(h.fake.spoken, hasLength(2));
      h.controller.dispose();
    });
  });

  test('一時停止中の再開以外の操作（スキップ・回答）は無視する', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.controller.pause();
      h.controller.skip();
      h.controller.answer(0);
      expect(h.phase, NagaraPhase.paused);
      expect(h.controller.state.index, 0);
      h.controller.resume();
      h.controller.resume();
      expect(h.phase, NagaraPhase.waitingAnswer);
      h.controller.dispose();
    });
  });

  test('スキップで次の問題へ（答えなしで数え、誤答にはしない）', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.controller.skip();
      a.flushMicrotasks();
      expect(h.controller.state.index, 1);
      expect(h.controller.state.completed, 1);
      expect(h.phase, NagaraPhase.waitingAnswer);
      expect(h.wrong, isEmpty);
      expect(h.unanswered, isEmpty);
      h.controller.dispose();
    });
  });

  test('最後の問題でスキップすると終わる', () {
    fakeAsync((a) {
      final h = _Harness(n: 1);
      h.controller.start();
      a.flushMicrotasks();
      h.controller.skip();
      expect(h.phase, NagaraPhase.finished);
      expect(h.controller.state.finishReason, NagaraFinishReason.completed);
    });
  });

  test('停止すると読み上げもタイマーも止まり、終了の理由は stopped', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      final stops = h.fake.stopCount;
      h.controller.stop();
      expect(h.phase, NagaraPhase.finished);
      expect(h.controller.state.finishReason, NagaraFinishReason.stopped);
      expect(h.finished.single.finishReason, NagaraFinishReason.stopped);
      expect(h.fake.stopCount, greaterThan(stops));
      final spoken = h.fake.spoken.length;
      _tick(a, 120);
      expect(h.fake.spoken.length, spoken);
      expect(h.phase, NagaraPhase.finished);
    });
  });

  test('dispose（画面離脱）で読み上げとタイマーが止まり、通知も来ない', () {
    fakeAsync((a) {
      final h = _Harness();
      var notified = 0;
      h.controller.start();
      h.controller.addListener(() => notified++);
      a.flushMicrotasks();
      final stops = h.fake.stopCount;
      final spoken = h.fake.spoken.length;
      final notifiedBefore = notified;
      h.controller.dispose();
      expect(h.fake.stopCount, greaterThan(stops));
      _tick(a, 120);
      expect(h.fake.spoken.length, spoken);
      expect(notified, notifiedBefore);
      h.controller.start();
      h.controller.pause();
      h.controller.stop();
    });
  });

  test('読み上げ中に離脱しても、保留中の読み上げの続きは動かない', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.holdUntilReleased = true;
      h.controller.start();
      a.flushMicrotasks();
      h.controller.dispose();
      a.flushMicrotasks();
      _tick(a, 60);
      expect(h.fake.spoken, hasLength(1));
    });
  });

  test('音声が使えなくても例外を出さず、読み上げを飛ばして画面だけで進む', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.error = StateError('tts unavailable');
      h.controller.start();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.waitingAnswer);
      expect(h.controller.state.speechFailed, isTrue);
      _tick(a, 5 + 2 + 5 + 2 + 5);
      expect(h.phase, NagaraPhase.finished);
      expect(h.fake.spoken, isEmpty);
    });
  });

  test('読み上げの同期例外も受け止める', () {
    fakeAsync((a) {
      final h = _Harness(backend: _ThrowingBackend());
      h.controller.start();
      a.flushMicrotasks();
      expect(h.controller.state.speechFailed, isTrue);
      expect(h.phase, NagaraPhase.waitingAnswer);
      h.controller.dispose();
    });
  });

  test('タップで誤答すると onWrongAnswer に返り、正解と解説を読んで次へ進む', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.controller.answer(2);
      a.flushMicrotasks();
      expect(h.wrong, [('q1', 2)]);
      expect(h.controller.state.result, NagaraResult.incorrect);
      expect(h.controller.state.chosen, 2);
      expect(h.controller.state.completed, 1);
      expect(h.fake.spoken.last, contains(NagaraStrings.ja.checkSpoken));
      expect(h.fake.spoken.last, contains('正解はア、こたえAです'));
      expect(h.fake.spoken.last, contains('かいせつ1'));
      expect(h.phase, NagaraPhase.pausedBetween);
      _tick(a, 2);
      expect(h.controller.state.index, 1);
      expect(h.controller.state.result, isNull);
      h.controller.dispose();
    });
  });

  test('正解のタップは誤答として返さず、正誤を読む', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.controller.answer(0);
      a.flushMicrotasks();
      expect(h.wrong, isEmpty);
      expect(h.controller.state.correctCount, 1);
      expect(h.fake.spoken.last, startsWith(NagaraStrings.ja.correctSpoken));
      h.controller.dispose();
    });
  });

  test('問題を読んでいる最中のタップも受け付け、読み上げを止めて答え合わせへ', () {
    fakeAsync((a) {
      final h = _Harness();
      h.fake.holdUntilReleased = true;
      h.controller.start();
      a.flushMicrotasks();
      h.controller.answer(1);
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.readingAnswer);
      h.fake.release();
      a.flushMicrotasks();
      expect(h.phase, NagaraPhase.pausedBetween);
      h.controller.dispose();
    });
  });

  test('答え合わせのあとや範囲外のタップは無視する', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.controller.answer(9);
      h.controller.answer(-1);
      expect(h.phase, NagaraPhase.waitingAnswer);
      h.controller.answer(1);
      a.flushMicrotasks();
      h.controller.answer(0);
      expect(h.wrong, hasLength(1));
      expect(h.controller.state.completed, 1);
      h.controller.dispose();
    });
  });

  test('解説を読まない設定なら解説を読まない。問題を読まない設定なら考える間から始まる', () {
    fakeAsync((a) {
      final h = _Harness(
        s: const HandsFreeSettings(speakQuestion: false, speakExplanation: false, thinkSeconds: 3),
      );
      h.controller.start();
      expect(h.phase, NagaraPhase.waitingAnswer);
      expect(h.fake.spoken, isEmpty);
      _tick(a, 3);
      expect(h.fake.spoken.single, contains('正解はア'));
      expect(h.fake.spoken.single, isNot(contains('かいせつ')));
      h.controller.dispose();
    });
  });

  test('自動で次へ進まない設定なら、スキップするまで間で待つ', () {
    fakeAsync((a) {
      final h = _Harness(s: const HandsFreeSettings(thinkSeconds: 3, autoAdvance: false));
      h.controller.start();
      a.flushMicrotasks();
      _tick(a, 3);
      expect(h.phase, NagaraPhase.pausedBetween);
      _tick(a, 600);
      expect(h.phase, NagaraPhase.pausedBetween);
      expect(h.controller.state.index, 0);
      h.controller.skip();
      a.flushMicrotasks();
      expect(h.controller.state.index, 1);
      h.controller.dispose();
    });
  });

  test('設定は呼ぶたびに読む（考える間・次までの間を途中で変えられる）', () {
    fakeAsync((a) {
      final h = _Harness();
      h.controller.start();
      a.flushMicrotasks();
      h.settings = h.settings.copyWith(thinkSeconds: 12, betweenSeconds: 1);
      h.controller.pause();
      h.controller.resume();
      a.flushMicrotasks();
      _tick(a, 11);
      expect(h.phase, NagaraPhase.waitingAnswer);
      _tick(a, 1);
      expect(h.phase, NagaraPhase.pausedBetween);
      _tick(a, 1);
      expect(h.controller.state.index, 1);
      h.controller.dispose();
    });
  });

  test('ひと続きの上限問数に達すると、休憩を促す終わり方（limitReached）', () {
    fakeAsync((a) {
      final h = _Harness(n: 5, max: 2);
      expect(h.controller.total, 2);
      h.controller.start();
      a.flushMicrotasks();
      _tick(a, 5 + 2 + 5);
      expect(h.phase, NagaraPhase.finished);
      expect(h.controller.state.finishReason, NagaraFinishReason.limitReached);
      expect(h.controller.state.completed, 2);
    });
  });

  test('問題が 0 件なら、始めるとすぐ終わる', () {
    final c = NagaraSessionController(
      questions: const [],
      backend: FakeSpeechBackend(),
      settings: () => const HandsFreeSettings(),
    );
    c.start();
    expect(c.state.phase, NagaraPhase.finished);
    expect(c.currentQuestion, isNull);
  });

  test('アプリのコールバックが例外を投げてもセッションは止まらない', () {
    fakeAsync((a) {
      final c = NagaraSessionController(
        questions: _qs(),
        backend: FakeSpeechBackend(),
        settings: () => const HandsFreeSettings(),
        onWrongAnswer: (_, __) => throw StateError('app bug'),
      );
      c.start();
      a.flushMicrotasks();
      c.answer(1);
      a.flushMicrotasks();
      expect(c.state.phase, NagaraPhase.pausedBetween);
      c.dispose();
    });
  });
}

class _ThrowingBackend implements SpeechBackend {
  @override
  Future<void> speak(String text, {double rate = 1.0}) => throw StateError('sync');
  @override
  Future<void> stop() => throw StateError('sync');
}
