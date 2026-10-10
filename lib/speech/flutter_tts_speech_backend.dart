import 'package:flutter_tts/flutter_tts.dart';

import '../hands_free/speech.dart';

/// 端末標準の音声合成（flutter_tts）による読み上げ。ながら学習モードで使う。
class FlutterTtsSpeechBackend implements SpeechBackend {
  FlutterTtsSpeechBackend({FlutterTts? tts, this.language = 'ja-JP'}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// 読み上げの言語（BCP 47）。
  final String language;
  bool _ready = false;

  Future<void> _prepare() async {
    if (_ready) return;
    await _tts.setLanguage(language);
    _ready = true;
  }

  /// 標準(1.0)を flutter_tts の標準(0.5)に合わせ、0.1〜1.0 に収める。
  static double ttsRate(double rate) => (rate * 0.5).clamp(0.1, 1.0).toDouble();

  @override
  Future<void> speak(String text, {double rate = 1.0}) async {
    await _prepare();
    await _tts.setSpeechRate(ttsRate(rate));
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
