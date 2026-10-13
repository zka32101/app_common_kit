import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';

FeatureFlags _make({FeatureFlagBackend? backend, FeatureFlagCache? cache}) =>
    FeatureFlags(
      defaults: {'newHome': false, 'maxItems': 10, 'ratio': 0.5, 'label': 'a'},
      backend: backend,
      cache: cache,
    );

void main() {
  test('load 前は既定値', () {
    final f = _make();
    expect(f.getBool('newHome'), false);
    expect(f.getInt('maxItems'), 10);
  });

  test('リモート値で上書きし、キャッシュへ保存する', () async {
    final cache = InMemoryFeatureFlagCache();
    final f = _make(
      backend: FakeFeatureFlagBackend({'newHome': true, 'maxItems': 20}),
      cache: cache,
    );
    expect(await f.load(), isTrue);
    expect(f.getBool('newHome'), true);
    expect(f.getInt('maxItems'), 20);
    expect((await cache.load())['maxItems'], 20);
  });

  test('取得失敗でも例外を出さず、前回値を使う', () async {
    final cache = InMemoryFeatureFlagCache();
    await cache.save({'newHome': true});
    final f = _make(
      backend: FakeFeatureFlagBackend({}, StateError('x')),
      cache: cache,
    );
    expect(await f.load(), isFalse);
    expect(f.getBool('newHome'), true);
  });

  test('型が違う値は無視して既定値。int は double として読める', () async {
    final f = _make(
      backend: FakeFeatureFlagBackend({'newHome': 'yes', 'ratio': 1}),
    );
    await f.load();
    expect(f.getBool('newHome'), false);
    expect(f.getDouble('ratio'), 1.0);
  });

  test('override が最優先。未登録キーや型違いの取得は ArgumentError', () async {
    final f = _make(backend: FakeFeatureFlagBackend({'label': 'b'}));
    await f.load();
    f.override('label', 'c');
    expect(f.getString('label'), 'c');
    f.clearOverrides();
    expect(f.getString('label'), 'b');
    expect(() => f.getBool('nothing'), throwsArgumentError);
    expect(() => f.getInt('label'), throwsArgumentError);
  });
}
