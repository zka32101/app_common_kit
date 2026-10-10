/// ながら学習モードの音声読み上げ（端末標準の音声合成 flutter_tts）と、選択式の表示。
///
/// `package:app_common_kit/app_common_kit.dart` とは別の入口にしている。アプリが同じ名前の
/// 部品を自前で持っていても、この入口を読み込むまでは名前が衝突しない。
library;

export 'hands_free/flutter_tts_speech_backend.dart';
export 'hands_free/hands_free_choice_body.dart';
export 'hands_free/hands_free_providers.dart';
