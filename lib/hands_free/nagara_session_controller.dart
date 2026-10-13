import 'dart:async';

import 'hands_free_settings.dart';
import 'nagara_strings.dart';
import 'speech.dart';

/// ながらセッションで出す 1 問（選択式）。
class NagaraQuestion {
  const NagaraQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    this.explanation,
  });

  /// 問題の識別子（アプリ側の問題 ID）。誤答の復習キューに積むときに使う。
  final String id;
  final String prompt;

  /// 画面と読み上げに出す順に並べた選択肢。
  final List<String> choices;

  /// [choices] の中の正解の位置（0 始まり）。
  final int correctIndex;

  /// 解説。null か空なら読まない。
  final String? explanation;
}

/// ながらセッションの進行状態。
enum NagaraPhase {
  /// まだ始めていない。
  idle,

  /// 問題と選択肢を読んでいる。
  readingQuestion,

  /// 読み終えて、考える間を待っている。
  waitingAnswer,

  /// 正解（と解説）を読んでいる。
  readingAnswer,

  /// 次の問題の前の間（自動で進まない設定なら、スキップで進むまでここで待つ）。
  pausedBetween,

  /// 一時停止中。
  paused,

  /// 終わった（理由は [NagaraFinishReason]）。
  finished,
}

/// 1 問ごとの結果。
enum NagaraResult { correct, incorrect, unanswered }

enum NagaraFinishReason {
  /// 最後の問題まで終えた。
  completed,

  /// アプリが指定した上限問数に達した（休憩を促す）。
  limitReached,

  /// 停止ボタンなどで止めた。
  stopped,
}

/// [NagaraSessionController] の、ある時点の状態。
class NagaraSessionState {
  const NagaraSessionState({
    required this.phase,
    required this.index,
    required this.total,
    required this.completed,
    required this.correctCount,
    required this.chosen,
    required this.result,
    required this.speechFailed,
    required this.pausedFrom,
    required this.finishReason,
  });

  final NagaraPhase phase;

  /// 今の問題の位置（0 始まり）。
  final int index;

  /// このセッションで出す問題数（上限を反映）。
  final int total;

  /// 答え合わせまで終えた問題数（スキップも数える）。
  final int completed;
  final int correctCount;

  /// タップで選んだ選択肢（なければ null）。
  final int? chosen;

  /// 今の問題の結果（答え合わせ前は null）。
  final NagaraResult? result;

  /// 音声が使えず、画面だけで進めたことがあるか。
  final bool speechFailed;

  /// 一時停止する前の状態（[phase] が paused のときだけ）。
  final NagaraPhase? pausedFrom;
  final NagaraFinishReason? finishReason;

  int get remaining => total - completed;
  bool get isFinished => phase == NagaraPhase.finished;
  bool get isPaused => phase == NagaraPhase.paused;
  bool get isRunning => phase != NagaraPhase.idle && !isFinished;
}

typedef NagaraTimerFactory = Timer Function(Duration duration, void Function() callback);

/// 画面点灯中の自動進行ハンズフリー学習を進める、純 Dart のコントローラ。
///
/// 流れ: 問題と選択肢を読む → 設定の秒数だけ考える間 → 正解と解説を読む →
/// 次の問題の前の短い間 → 次へ。選択肢のタップでも答えられ、その場合は正誤を読んで次へ進む。
///
/// - 一時停止中に再開すると、止めた段階の頭から（読み上げ中なら読み直し、待ち時間なら待ち直し）。
/// - [dispose] と [stop] で、読み上げとタイマーを必ず止める。画面を離れるときは [dispose] を呼ぶ。
/// - 音声が使えず読み上げが失敗しても、例外は出さず、その読み上げを飛ばして先へ進む
///   （[NagaraSessionState.speechFailed] が true になる）。
/// - [backend] が [AwaitableSpeechBackend] でなければ、文字数からの目安の時間だけ待つ。
///   [AwaitableSpeechBackend] でも、完了通知が来ない端末のために目安の約 2 倍 + 5 秒で打ち切る。
/// - アプリのコールバックが例外を投げても、セッションは止めない。
class NagaraSessionController {
  NagaraSessionController({
    required List<NagaraQuestion> questions,
    required this.backend,
    required this.settings,
    this.strings = NagaraStrings.ja,
    int? maxQuestions,
    this.onAnswered,
    this.onWrongAnswer,
    this.onUnanswered,
    this.onFinished,
    NagaraTimerFactory? timerFactory,
  })  : questions = List.unmodifiable(questions),
        total = (maxQuestions != null && maxQuestions > 0 && maxQuestions < questions.length)
            ? maxQuestions
            : questions.length,
        _timerFactory = timerFactory ?? ((d, cb) => Timer(d, cb));

  final List<NagaraQuestion> questions;
  final SpeechBackend backend;

  /// 現在の設定（呼ぶたびに最新を読む。例: `() => ref.read(handsFreeProvider)`）。
  final HandsFreeSettings Function() settings;
  final NagaraStrings strings;

  /// このセッションで出す問題数。アプリが指定した上限（ひと続きの上限）を反映する。
  final int total;

  /// タップで答えが確定したとき（正答・誤答の両方）。`chosen` は [NagaraQuestion.choices] の位置、
  /// `correct` は正解かどうか。アプリの通常の解答と同じ記録経路（履歴・間隔反復など）に載せる。
  ///
  /// - 1 問につき最大 1 回。呼び出し順は「解答確定 → onAnswered → （誤答なら onWrongAnswer）」。
  /// - 考える間に答えがなかった問題（[onUnanswered]）とスキップでは呼ばない（未回答は解答ではない）。
  /// - 一時停止・再開、画面離脱では呼ばない／重複しない。
  final void Function(NagaraQuestion question, int chosen, bool correct)? onAnswered;

  /// タップ回答で正解でなかったとき。アプリが復習キューや間違いノートに積む。
  final void Function(NagaraQuestion question, int chosen)? onWrongAnswer;

  /// 考える間のうちに答えがなかったとき。
  final void Function(NagaraQuestion question)? onUnanswered;

  /// 終わったとき（最後まで・上限・停止のいずれも）。
  final void Function(NagaraSessionState summary)? onFinished;

  final NagaraTimerFactory _timerFactory;

  NagaraPhase _phase = NagaraPhase.idle;
  NagaraPhase? _pausedFrom;
  NagaraFinishReason? _reason;
  int _index = 0;
  int _completed = 0;
  int _correct = 0;
  int? _chosen;
  NagaraResult? _result;
  bool _speechFailed = false;
  bool _disposed = false;

  int _gen = 0;
  Timer? _timer;
  void Function()? _finishSpeech;
  final List<void Function()> _listeners = [];

  NagaraSessionState get state => NagaraSessionState(
        phase: _phase,
        index: _index,
        total: total,
        completed: _completed,
        correctCount: _correct,
        chosen: _chosen,
        result: _result,
        speechFailed: _speechFailed,
        pausedFrom: _pausedFrom,
        finishReason: _reason,
      );

  /// 今の問題。問題が 0 件のときは null。
  NagaraQuestion? get currentQuestion =>
      total > 0 && _index < questions.length ? questions[_index] : null;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// 読み上げ時間の目安（完了通知を使えないときの待ち時間）。
  static Duration estimateSpeechDuration(String text, double rate) {
    final r = rate <= 0 ? 1.0 : rate;
    return Duration(milliseconds: (600 + text.length * 200 / r).round());
  }

  /// 始める。2 回目以降は何もしない。
  void start() {
    if (_disposed || _phase != NagaraPhase.idle) return;
    if (total == 0) {
      _finish(NagaraFinishReason.completed);
      return;
    }
    _beginQuestion();
  }

  /// 一時停止。読み上げとタイマーを止める。
  void pause() {
    if (_disposed) return;
    if (_phase == NagaraPhase.idle || _phase == NagaraPhase.finished || _phase == NagaraPhase.paused) {
      return;
    }
    _pausedFrom = _phase;
    _bump();
    _phase = NagaraPhase.paused;
    _notify();
  }

  /// 再開。止めた段階の頭から進める。
  void resume() {
    if (_disposed || _phase != NagaraPhase.paused) return;
    final from = _pausedFrom ?? NagaraPhase.readingQuestion;
    _pausedFrom = null;
    final gen = _bump();
    switch (from) {
      case NagaraPhase.waitingAnswer:
        _enterWaiting(gen);
      case NagaraPhase.readingAnswer:
        _phase = NagaraPhase.readingAnswer;
        _notify();
        _readResult(gen);
      case NagaraPhase.pausedBetween:
        _enterBetween(gen);
      default:
        _beginQuestion();
    }
  }

  /// 今の問題を飛ばして次へ（答え合わせの前なら、答えなしで数える）。
  void skip() {
    if (_disposed) return;
    switch (_phase) {
      case NagaraPhase.readingQuestion:
      case NagaraPhase.waitingAnswer:
        _completed++;
        _result = NagaraResult.unanswered;
      case NagaraPhase.readingAnswer:
      case NagaraPhase.pausedBetween:
        break;
      default:
        return;
    }
    _bump();
    _advance();
  }

  /// 止めて、終わりにする。
  void stop() {
    if (_disposed || _phase == NagaraPhase.idle || _phase == NagaraPhase.finished) return;
    _finish(NagaraFinishReason.stopped);
  }

  /// タップでの回答。読み上げ中・考える間のときだけ受け付ける。
  void answer(int chosen) {
    if (_disposed) return;
    if (_phase != NagaraPhase.readingQuestion && _phase != NagaraPhase.waitingAnswer) return;
    final q = currentQuestion;
    if (q == null || chosen < 0 || chosen >= q.choices.length) return;
    final gen = _bump();
    _chosen = chosen;
    final ok = chosen == q.correctIndex;
    _result = ok ? NagaraResult.correct : NagaraResult.incorrect;
    _completed++;
    if (ok) _correct++;
    _safe(() => onAnswered?.call(q, chosen, ok));
    if (!ok) _safe(() => onWrongAnswer?.call(q, chosen));
    _phase = NagaraPhase.readingAnswer;
    _notify();
    _readResult(gen);
  }

  /// 読み上げとタイマーを止めて、後始末をする。画面を離れるときに必ず呼ぶ。
  void dispose() {
    if (_disposed) return;
    _bump();
    _disposed = true;
    _listeners.clear();
  }

  // ---- 内部 ----

  /// 進行中の読み上げ・タイマーを止め、世代を進める（古い処理の続きを無効にする）。
  int _bump() {
    _gen++;
    _timer?.cancel();
    _timer = null;
    final finish = _finishSpeech;
    _finishSpeech = null;
    finish?.call();
    _stopBackend();
    return _gen;
  }

  void _stopBackend() {
    try {
      backend.stop().catchError((Object _) {});
    } catch (_) {}
  }

  void _notify() {
    if (_disposed) return;
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void _safe(void Function() f) {
    try {
      f();
    } catch (_) {}
  }

  void _startTimer(int gen, Duration d, void Function() callback) {
    _timer?.cancel();
    _timer = _timerFactory(d, () {
      _timer = null;
      if (gen == _gen && !_disposed) callback();
    });
  }

  void _beginQuestion() {
    final gen = _bump();
    _chosen = null;
    _result = null;
    _phase = NagaraPhase.readingQuestion;
    _notify();
    _readQuestion(gen);
  }

  Future<void> _readQuestion(int gen) async {
    final q = currentQuestion;
    if (q != null && settings().speakQuestion) {
      await _say(questionReadAloudText(q.prompt, q.choices), gen);
      if (gen != _gen) return;
    }
    _enterWaiting(gen);
  }

  void _enterWaiting(int gen) {
    _phase = NagaraPhase.waitingAnswer;
    _notify();
    _startTimer(gen, Duration(seconds: settings().thinkSeconds), () {
      final g = _bump();
      _completed++;
      _result = NagaraResult.unanswered;
      final q = currentQuestion;
      if (q != null) _safe(() => onUnanswered?.call(q));
      _phase = NagaraPhase.readingAnswer;
      _notify();
      _readResult(g);
    });
  }

  /// 結果（正誤・正解・解説）を読んで、次の間へ。
  Future<void> _readResult(int gen) async {
    final q = currentQuestion;
    if (q != null) {
      await _say(_resultText(q), gen);
      if (gen != _gen) return;
    }
    _afterResult(gen);
  }

  String _resultText(NagaraQuestion q) {
    final parts = <String>[];
    final validIndex = q.correctIndex >= 0 && q.correctIndex < q.choices.length;
    final answerText = validIndex
        ? strings.answerIsSpoken(readAloudChoiceLabel(q.correctIndex), q.choices[q.correctIndex])
        : '';
    switch (_result) {
      case NagaraResult.correct:
        parts.add(strings.correctSpoken);
      case NagaraResult.incorrect:
        parts.add(strings.checkSpoken);
        if (answerText.isNotEmpty) parts.add(answerText);
      default:
        parts.add(strings.unansweredSpoken);
        if (answerText.isNotEmpty) parts.add(answerText);
    }
    final e = q.explanation;
    if (settings().speakExplanation && e != null && e.trim().isNotEmpty) {
      parts.add('${strings.explanationSpoken}$e');
    }
    return parts.join(' ');
  }

  void _afterResult(int gen) {
    if (_index + 1 >= total) {
      _finish(total < questions.length ? NagaraFinishReason.limitReached : NagaraFinishReason.completed);
      return;
    }
    _enterBetween(gen);
  }

  void _enterBetween(int gen) {
    _phase = NagaraPhase.pausedBetween;
    _notify();
    final s = settings();
    if (s.autoAdvance) {
      _startTimer(gen, Duration(seconds: s.betweenSeconds), _advance);
    }
  }

  void _advance() {
    if (_index + 1 >= total) {
      _finish(total < questions.length ? NagaraFinishReason.limitReached : NagaraFinishReason.completed);
      return;
    }
    _index++;
    _beginQuestion();
  }

  void _finish(NagaraFinishReason reason) {
    _bump();
    _pausedFrom = null;
    _phase = NagaraPhase.finished;
    _reason = reason;
    _notify();
    final summary = state;
    _safe(() => onFinished?.call(summary));
  }

  /// [text] を読み、読み終わるまで待つ。失敗しても例外は出さず、そのまま先へ進む。
  Future<void> _say(String text, int gen) async {
    if (text.trim().isEmpty) return;
    final rate = settings().speechRate;
    final completer = Completer<void>();
    Timer? guard;
    void done() {
      if (completer.isCompleted) return;
      guard?.cancel();
      if (gen == _gen) _finishSpeech = null;
      completer.complete();
    }

    void failed() {
      if (gen == _gen && !_speechFailed) {
        _speechFailed = true;
        _notify();
      }
      done();
    }

    _finishSpeech = done;
    final estimate = estimateSpeechDuration(text, rate);
    final b = backend;
    if (b is AwaitableSpeechBackend) {
      guard = _timerFactory(estimate * 2 + const Duration(seconds: 5), () {
        _stopBackend();
        done();
      });
      Future<void>.sync(() => b.speakAndWait(text, rate: rate)).then((_) => done(), onError: (Object _) => failed());
    } else {
      guard = _timerFactory(estimate, done);
      Future<void>.sync(() => b.speak(text, rate: rate)).then((_) {}, onError: (Object _) => failed());
    }
    await completer.future;
  }
}
