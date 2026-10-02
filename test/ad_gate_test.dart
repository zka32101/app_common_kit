import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBackend implements AdsBackend {
  int initCount = 0;
  int shown = 0;
  bool ready = true;
  AdConfig? lastConfig;

  @override
  Future<bool> initialize(AdConfig config) async {
    initCount++;
    lastConfig = config;
    return true;
  }

  @override
  Future<void> preloadInterstitial() async => ready = true;

  @override
  bool get isInterstitialReady => ready;

  @override
  Future<bool> showInterstitial() async {
    shown++;
    ready = false;
    return true;
  }

  @override
  Future<bool> showRewarded() async => true;

  @override
  Widget buildBanner(BannerPlacement placement) => const Text('banner');
}

const _prod = AdUnitIds(
  banner: 'ca-app-pub-1111111111111111/1',
  interstitial: 'ca-app-pub-1111111111111111/2',
  rewarded: 'ca-app-pub-1111111111111111/3',
);

void main() {
  late DateTime now;
  late FakeBackend backend;
  var hidden = false;

  Future<AdGate> makeGate({AdRules rules = const AdRules()}) async {
    SharedPreferences.setMockInitialValues({});
    return AdGate.init(
      config: AdConfig(unitIds: _prod, rules: rules),
      adsHidden: () => hidden,
      backend: backend,
      prefs: await SharedPreferences.getInstance(),
      clock: () => now,
    );
  }

  setUp(() {
    now = DateTime(2026, 10, 2, 9);
    backend = FakeBackend();
    hidden = false;
  });

  test('最短間隔（3分）内は出さず、経過後は出す', () async {
    final gate = await makeGate();
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isTrue);
    now = now.add(const Duration(minutes: 2, seconds: 59));
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.mockExamResult), isTrue);
    expect(backend.shown, 2);
  });

  test('日次上限（5回）で止まり、翌日にリセットされる', () async {
    final gate = await makeGate();
    for (var i = 0; i < 5; i++) {
      expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isTrue);
      now = now.add(const Duration(minutes: 3));
    }
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
    now = DateTime(2026, 10, 3, 0, 1);
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isTrue);
  });

  test('ルールを updateRules で上書きできる', () async {
    final gate = await makeGate();
    gate.updateRules(const AdRules(interstitialDailyCap: 1));
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isTrue);
    now = now.add(const Duration(hours: 1));
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
  });

  test('有料（広告非表示）なら初期化も表示もしない', () async {
    hidden = true;
    final gate = await makeGate();
    expect(backend.initCount, 0);
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
    expect(await gate.showRewarded(), isFalse);
    expect(gate.banner(BannerPlacement.home), isA<SizedBox>());
    expect(backend.initCount, 0);
  });

  test('未ロードなら表示せずプリロードする', () async {
    final gate = await makeGate();
    backend.ready = false;
    expect(await gate.maybeShowInterstitial(InterstitialTrigger.sessionEnd), isFalse);
    expect(backend.ready, isTrue);
  });

  test('無料ならバナーが出る', () async {
    final gate = await makeGate();
    expect(gate.banner(BannerPlacement.home), isA<Text>());
  });

  test('リリースビルドでテストIDなら例外、本番IDなら通る', () {
    const test = AdUnitIds(
      banner: 'ca-app-pub-3940256099942544/6300978111',
      interstitial: 'ca-app-pub-3940256099942544/1033173712',
      rewarded: 'ca-app-pub-3940256099942544/5224354917',
    );
    expect(() => test.assertNoTestIdsInRelease(isRelease: true), throwsStateError);
    test.assertNoTestIdsInRelease(isRelease: false);
    _prod.assertNoTestIdsInRelease(isRelease: true);
  });

  test('init はリリース+テストIDで例外', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      AdGate.init(
        config: const AdConfig(
          unitIds: AdUnitIds(
            banner: 'ca-app-pub-3940256099942544/6300978111',
            interstitial: 'ca-app-pub-3940256099942544/1033173712',
            rewarded: 'ca-app-pub-3940256099942544/5224354917',
          ),
        ),
        adsHidden: () => false,
        backend: backend,
        isRelease: true,
      ),
      throwsStateError,
    );
  });
}
