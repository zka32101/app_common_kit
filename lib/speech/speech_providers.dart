import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hands_free/hands_free_settings.dart';
import '../hands_free/speech.dart';
import 'flutter_tts_speech_backend.dart';

/// 音声合成の窓口。既定は端末標準（flutter_tts）。テストでは [FakeSpeechBackend] で上書きする。
final speechBackendProvider = Provider<SpeechBackend>((ref) => FlutterTtsSpeechBackend());

/// ながら学習モードの読み上げ。設定（[handsFreeProvider]）に従って問題・解説を自動で読む。
final handsFreeSpeakerProvider = Provider<HandsFreeSpeaker>(
  (ref) => HandsFreeSpeaker(
    backend: ref.watch(speechBackendProvider),
    settings: () => ref.read(handsFreeProvider),
  ),
);
