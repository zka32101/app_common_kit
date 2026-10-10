import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('送り先が無ければ何もしない', () async {
    expect(await CrashReporter(null).record(StateError('x'), null), isFalse);
  });

  test('エラーを送り、理由の個人情報を伏せる', () async {
    final fake = FakeCrashBackend();
    final r = CrashReporter(fake);
    expect(await r.record(StateError('x'), null, reason: 'a@b.com 090-1234-5678'), isTrue);
    expect(fake.errors.single.reason, '[email] [number]');
  });

  test('長いトークンを伏せ、長さを切り詰める', () {
    expect(CrashReporter.scrub('t=${'a' * 40}'), 't=[token]');
    expect(CrashReporter.scrub('あ' * 500).length, CrashReporter.maxLogLength);
  });

  test('同じエラーは時間内に1回だけ、時間が過ぎれば再び送る', () async {
    var now = DateTime(2026, 1, 1);
    final fake = FakeCrashBackend();
    final r = CrashReporter(fake, clock: () => now);
    expect(await r.record(StateError('x'), null), isTrue);
    expect(await r.record(StateError('x'), null), isFalse);
    expect(await r.record(ArgumentError('y'), null), isTrue);
    now = now.add(const Duration(minutes: 2));
    expect(await r.record(StateError('x'), null), isTrue);
    expect(fake.errors.length, 3);
  });

  test('送信が例外でも止まらない', () async {
    final r = CrashReporter(_Throwing());
    expect(await r.record(StateError('x'), null), isFalse);
    await r.log('ok');
  });

  test('ログも整形して送る', () async {
    final fake = FakeCrashBackend();
    await CrashReporter(fake).log('mail a@b.com');
    expect(fake.logs.single, 'mail [email]');
  });
}

class _Throwing implements CrashBackend {
  @override
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal, String? reason}) =>
      throw StateError('boom');
  @override
  Future<void> log(String message) => throw StateError('boom');
}
