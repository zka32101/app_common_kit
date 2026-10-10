import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Throwing implements AnalyticsBackend {
  @override
  Future<void> logEvent(String name, Map<String, Object> params) async => throw StateError('x');
}

void main() {
  test('イベント名の検査', () {
    expect(Analytics.isValidName('study_start'), isTrue);
    expect(Analytics.isValidName('Study'), isFalse);
    expect(Analytics.isValidName('1abc'), isFalse);
    expect(Analytics.isValidName('a' * 41), isFalse);
    expect(Analytics.isValidName(''), isFalse);
    for (final n in [AnalyticsEvents.sessionStart, AnalyticsEvents.studyComplete, AnalyticsEvents.languageChanged]) {
      expect(Analytics.isValidName(n), isTrue);
    }
  });

  test('個人情報らしいキー・不正な値は落とし、長い文字列は切る', () {
    final p = Analytics.sanitize({
      'email': 'a@b.c',
      'user_id': 'u1',
      'auth_token': 't',
      'score': 80,
      'passed': true,
      'cert': 'x' * 300,
      'list': [1],
      'nul': null,
      'Bad Key': 1,
    });
    expect(p.keys.toSet(), {'score', 'passed', 'cert'});
    expect((p['cert'] as String).length, 100);
  });

  test('パラメータは25個まで', () {
    final p = Analytics.sanitize({for (var i = 0; i < 40; i++) 'k$i': i});
    expect(p.length, 25);
  });

  test('送信する／不正な名前は送らない／送り先なしは何もしない', () async {
    final fake = FakeAnalyticsBackend();
    final a = Analytics(fake);
    expect(await a.log(AnalyticsEvents.studyStart, {'cert': 'it', 'email': 'x'}), isTrue);
    expect(fake.events.single.name, 'study_start');
    expect(fake.events.single.params, {'cert': 'it'});
    expect(await a.log('Bad Name'), isFalse);
    expect(fake.events.length, 1);
    expect(await Analytics(null).log('study_start'), isFalse);
  });

  test('送信の例外は握りつぶす', () async {
    expect(await Analytics(_Throwing()).log('study_start'), isFalse);
  });

  test('provider は既定で送り先なし、override で差し替えられる', () async {
    final fake = FakeAnalyticsBackend();
    final c = ProviderContainer(overrides: [analyticsProvider.overrideWithValue(Analytics(fake))]);
    addTearDown(c.dispose);
    await c.read(analyticsProvider).log('language_changed', {'to': 'en'});
    expect(fake.events.length, 1);
    final d = ProviderContainer();
    addTearDown(d.dispose);
    expect(d.read(analyticsProvider).backend, isNull);
  });
}
