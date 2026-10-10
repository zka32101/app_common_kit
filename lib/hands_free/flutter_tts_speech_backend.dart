import 'speech.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 端末標準の音声合成（flutter_tts）による読み上げ。ながら学習モードで使う。
class FlutterTtsSpeechBackend implements SpeechBackend {
  FlutterTtsSpeechBackend({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> _prepare() async {
    if (_ready) return;
    await _tts.setLanguage('ja-JP');
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
