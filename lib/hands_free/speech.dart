import 'hands_free_settings.dart';

/// 音声合成の窓口。既定の実体は端末標準の読み上げ（[FlutterTtsSpeechBackend]）。
/// 別の実装を使うときは `speechBackendProvider` を上書きする。
abstract class SpeechBackend {
  /// [text] を読み上げる。[rate] は 1.0 が標準。
  Future<void> speak(String text, {double rate = 1.0});

  Future<void> stop();
}

/// テスト・プレビュー用。読み上げた内容を記録するだけで、音は出さない。
class FakeSpeechBackend implements SpeechBackend {
  final List<String> spoken = [];
  final List<double> rates = [];
  int stopCount = 0;

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {
    spoken.add(text);
    rates.add(rate);
  }

  @override
  Future<void> stop() async => stopCount++;
}

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
