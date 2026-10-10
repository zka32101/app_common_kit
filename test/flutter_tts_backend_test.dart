import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ttsRate は標準1.0を0.5に合わせ、0.1〜1.0に収める', () {
    expect(FlutterTtsSpeechBackend.ttsRate(1.0), 0.5);
    expect(FlutterTtsSpeechBackend.ttsRate(0.0), 0.1);
    expect(FlutterTtsSpeechBackend.ttsRate(10), 1.0);
  });
}
