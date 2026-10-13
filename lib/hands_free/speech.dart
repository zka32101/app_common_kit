import 'dart:async';

import 'hands_free_settings.dart';

/// 音声合成の窓口。既定の実体は端末標準の読み上げ（[FlutterTtsSpeechBackend]）。
/// 別の実装を使うときは `speechBackendProvider` を上書きする。
abstract class SpeechBackend {
  /// [text] を読み上げる。[rate] は 1.0 が標準。
  Future<void> speak(String text, {double rate = 1.0});

  Future<void> stop();
}

/// 読み上げが終わるまで待てる [SpeechBackend]。ながらセッション（[NagaraSessionController]）が使う。
///
/// [SpeechBackend] に足すと既存アプリの実装（`implements SpeechBackend`）が壊れるため、別の型にした。
/// これを実装していない [SpeechBackend] でも、ながらセッションは文字数からの目安の時間で進む。
///
/// 失敗の扱い: [speakAndWait] は、音声が使えないときは例外を投げてよい。
/// ながらセッション側で受け止め、その読み上げを飛ばして画面だけで先へ進む（学習を止めない）。
abstract class AwaitableSpeechBackend implements SpeechBackend {
  /// [text] を読み上げ、読み終わる（または [stop] で打ち切られる）と完了する。
  Future<void> speakAndWait(String text, {double rate = 1.0});
}

/// テスト・プレビュー用。読み上げた内容を記録するだけで、音は出さない。
///
/// 既定では [speakAndWait] はすぐ完了する。完了のタイミングを試すときは、
/// [speakDuration] で時間をかけるか、[holdUntilReleased] を true にして [release] で完了させる。
class FakeSpeechBackend implements AwaitableSpeechBackend {
  final List<String> spoken = [];
  final List<double> rates = [];
  int stopCount = 0;

  /// [speakAndWait] が完了するまでの時間。
  Duration speakDuration = Duration.zero;

  /// true なら、[release] か [stop] が呼ばれるまで [speakAndWait] は完了しない。
  bool holdUntilReleased = false;

  /// 設定すると、[speak] と [speakAndWait] はこの例外を投げる（音声が使えない状況を試す）。
  Object? error;

  final List<Completer<void>> _pending = [];

  /// 完了待ちの [speakAndWait] の数。
  int get pendingCount => _pending.length;

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {
    if (error != null) throw error!;
    spoken.add(text);
    rates.add(rate);
  }

  @override
  Future<void> speakAndWait(String text, {double rate = 1.0}) async {
    await speak(text, rate: rate);
    if (holdUntilReleased) {
      final c = Completer<void>();
      _pending.add(c);
      await c.future;
      return;
    }
    if (speakDuration > Duration.zero) {
      final c = Completer<void>();
      _pending.add(c);
      final t = Timer(speakDuration, () {
        if (!c.isCompleted) c.complete();
      });
      await c.future;
      t.cancel();
    }
  }

  /// 完了待ちの読み上げをすべて完了させる。
  void release() {
    for (final c in List.of(_pending)) {
      if (!c.isCompleted) c.complete();
    }
    _pending.clear();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    release();
  }
}

/// 選択肢を読むときのラベル（ア・イ・ウ…）。8 を超えたら数字。
String readAloudChoiceLabel(int index) => index < _kanaLabels.length ? _kanaLabels[index] : '${index + 1}';

const _kanaLabels = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク'];

/// 問題文と選択肢を、読み上げ用の文にする。
/// 例:「問題。〜。選択肢。ア、〜。イ、〜。」ラベルが足りなければ 9 以降は数字で読む。
String questionReadAloudText(
  String prompt,
  List<String> choices, {
  List<String> labels = _kanaLabels,
}) {
  final buffer = StringBuffer('問題。$prompt。');
  if (choices.isNotEmpty) {
    buffer.write('選択肢。');
    for (var i = 0; i < choices.length; i++) {
      final label = i < labels.length ? labels[i] : '${i + 1}';
      buffer.write('$label、${choices[i]}。');
    }
  }
  return buffer.toString();
}

/// 片手・ながら学習モードの読み上げ。設定（[HandsFreeSettings]）に従って自動で読む。
/// 端末の音声合成が使えないなどで失敗しても、例外は出さず false を返す（学習を止めない）。
class HandsFreeSpeaker {
  HandsFreeSpeaker({required this.backend, required this.settings});

  final SpeechBackend backend;

  /// 現在の設定（呼ぶたびに最新を読む。例: `() => ref.read(handsFreeProvider)`）。
  final HandsFreeSettings Function() settings;

  /// 問題文と選択肢を、モードが有効で「問題を読み上げる」がオンのときだけ自動で読む。
  Future<bool> readQuestion(String prompt, List<String> choices) async {
    final s = settings();
    if (!s.enabled || !s.speakQuestion) return false;
    return _speak(questionReadAloudText(prompt, choices), s.speechRate);
  }

  /// 解説を、モードが有効で「解説を読み上げる」がオンのときだけ自動で読む。
  Future<bool> readExplanation(String explanation) async {
    final s = settings();
    if (!s.enabled || !s.speakExplanation) return false;
    return _speak(explanation, s.speechRate);
  }

  /// 読み上げボタンを押したとき。モードやオン・オフに関わらず、すぐ読む。
  Future<bool> speakNow(String text) => _speak(text, settings().speechRate);

  Future<void> stop() async {
    try {
      await backend.stop();
    } catch (_) {}
  }

  Future<bool> _speak(String text, double rate) async {
    if (text.trim().isEmpty) return false;
    try {
      await backend.stop();
      await backend.speak(text, rate: rate);
      return true;
    } catch (_) {
      return false;
    }
  }
}
