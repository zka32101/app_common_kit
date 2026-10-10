import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  DateTime now = DateTime(2026, 1, 1);
  DateTime call() => now;
  void advanceDays(int d) => now = now.add(Duration(days: d));
}

class _ThrowingBackend implements ReviewBackend {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => throw Exception('plugin error');
}

Future<(ReviewPromptService, FakeReviewBackend, _Clock, InMemoryReviewStore)> _make({
  ReviewPromptRules rules = ReviewPromptRules.standard,
  bool available = true,
}) async {
  final clock = _Clock();
  final backend = FakeReviewBackend(available: available);
  final store = InMemoryReviewStore();
  final s = ReviewPromptService(store: store, backend: backend, rules: rules, clock: clock.call);
  await s.load();
  return (s, backend, clock, store);
}

/// 頼んでよい状態にする（日数と良い体験を満たす）。
Future<void> _ready(ReviewPromptService s, _Clock clock) async {
  clock.advanceDays(8);
  for (var i = 0; i < 3; i++) {
    await s.recordPositiveMoment();
  }
}

void main() {
  group('判定', () {
    test('初回起動から日が浅いうちは頼まない（tooEarly）', () async {
      final (s, _, clock, _) = await _make();
      for (var i = 0; i < 5; i++) {
        await s.recordPositiveMoment();
      }
      expect(s.evaluate(), ReviewDecision.tooEarly);
      clock.advanceDays(6);
      expect(s.evaluate(), ReviewDecision.tooEarly);
      clock.advanceDays(1);
      expect(s.evaluate(), ReviewDecision.ask);
    });

    test('良い体験が少ないうちは頼まない', () async {
      final (s, _, clock, _) = await _make();
      clock.advanceDays(30);
      await s.recordPositiveMoment();
      await s.recordPositiveMoment();
      expect(s.evaluate(), ReviewDecision.notEnoughMoments);
      await s.recordPositiveMoment();
      expect(s.evaluate(), ReviewDecision.ask);
    });

    test('頼むと、良い体験の数が0に戻り、同じ起動中にはもう頼まない', () async {
      final (s, backend, clock, _) = await _make();
      await _ready(s, clock);
      expect(await s.maybeRequest(), ReviewDecision.ask);
      expect(backend.requestCount, 1);
      expect(s.state.positiveMoments, 0);
      expect(s.state.askCount, 1);
      // 良い体験を溜め直しても、同じ起動中は頼まない
      clock.advanceDays(200);
      for (var i = 0; i < 3; i++) {
        await s.recordPositiveMoment();
      }
      expect(s.evaluate(), ReviewDecision.alreadyAskedThisSession);
    });

    test('前回から間隔が空かなければ頼まない（次の起動で）', () async {
      final (s, _, clock, store) = await _make();
      await _ready(s, clock);
      await s.maybeRequest();

      // アプリを再起動した想定（同じ保存先、新しいサービス）
      final restarted = ReviewPromptService(store: store, backend: FakeReviewBackend(), clock: clock.call);
      await restarted.load();
      clock.advanceDays(30);
      for (var i = 0; i < 3; i++) {
        await restarted.recordPositiveMoment();
      }
      expect(restarted.evaluate(), ReviewDecision.tooSoonSinceLastAsk);
      clock.advanceDays(90); // 前回から120日
      expect(restarted.evaluate(), ReviewDecision.ask);
    });

    test('生涯の上限に達したら頼まない', () async {
      const rules = ReviewPromptRules(maxAsksTotal: 2, minDaysBetweenAsks: 1, minDaysSinceFirstLaunch: 0);
      final clock = _Clock();
      final store = InMemoryReviewStore();
      Future<ReviewPromptService> start() async {
        final s = ReviewPromptService(store: store, backend: FakeReviewBackend(), rules: rules, clock: clock.call);
        await s.load();
        for (var i = 0; i < 3; i++) {
          await s.recordPositiveMoment();
        }
        return s;
      }

      for (var i = 0; i < 2; i++) {
        clock.advanceDays(10);
        expect(await (await start()).maybeRequest(), ReviewDecision.ask);
      }
      clock.advanceDays(10);
      expect(await (await start()).maybeRequest(), ReviewDecision.limitReached);
    });

    test('「楽しんでいない」と答えたら、しばらく頼まない', () async {
      final (s, backend, clock, _) = await _make();
      await _ready(s, clock);
      await s.declined();
      expect(s.evaluate(), ReviewDecision.declinedRecently);
      expect(await s.maybeRequest(), ReviewDecision.declinedRecently);
      expect(backend.requestCount, 0);
      clock.advanceDays(89);
      expect(s.evaluate(), ReviewDecision.declinedRecently);
      clock.advanceDays(1);
      expect(s.evaluate(), ReviewDecision.ask);
    });

    test('レビュー画面を出せない端末・プラグインの失敗では、頼んだことにしない', () async {
      final (s, backend, clock, _) = await _make(available: false);
      await _ready(s, clock);
      expect(await s.maybeRequest(), ReviewDecision.unavailable);
      expect(backend.requestCount, 0);
      expect(s.state.askCount, 0);
      expect(s.state.positiveMoments, 3); // 溜めた分は残る

      final clock2 = _Clock();
      final s2 = ReviewPromptService(store: InMemoryReviewStore(), backend: _ThrowingBackend(), clock: clock2.call);
      await s2.load();
      await _ready(s2, clock2);
      expect(await s2.maybeRequest(), ReviewDecision.unavailable); // 例外は出さない
      expect(s2.state.askCount, 0);
    });

    test('条件を変えられる', () async {
      const rules = ReviewPromptRules(minDaysSinceFirstLaunch: 0, minPositiveMoments: 1);
      final (s, _, _, _) = await _make(rules: rules);
      expect(s.evaluate(), ReviewDecision.notEnoughMoments);
      await s.recordPositiveMoment();
      expect(s.evaluate(), ReviewDecision.ask);
    });
  });

  group('保存', () {
    test('再起動しても状態が残り、初回起動の日付は変わらない', () async {
      final (s, _, clock, store) = await _make();
      final first = s.state.firstLaunch;
      expect(first, DateTime(2026, 1, 1));
      clock.advanceDays(3);
      await s.recordPositiveMoment();

      final again = ReviewPromptService(store: store, backend: FakeReviewBackend(), clock: clock.call);
      await again.load();
      expect(again.state.firstLaunch, first);
      expect(again.state.positiveMoments, 1);
    });

    test('壊れた保存データでも、読めた項目だけを使う', () {
      final st = ReviewState.fromJson({
        'firstLaunch': 'not a date',
        'positiveMoments': 'x',
        'askCount': -3,
        'lastAskedAt': '2026-02-03T00:00:00.000',
      });
      expect(st.firstLaunch, isNull);
      expect(st.positiveMoments, 0);
      expect(st.askCount, 0);
      expect(st.lastAskedAt, DateTime(2026, 2, 3));
      expect(ReviewState.fromJson(null).askCount, 0);
    });

    test('SharedPreferences に、アプリごとのキーで保存する', () async {
      SharedPreferences.setMockInitialValues({});
      final a = SharedPreferencesReviewStore('app_a');
      final b = SharedPreferencesReviewStore('app_b');
      await a.write({'askCount': 2});
      expect((await a.read())?['askCount'], 2);
      expect(await b.read(), isNull);
    });
  });

  group('確認ダイアログ（showReviewPrePrompt）', () {
    Future<void> open(WidgetTester tester, ReviewPromptService s, {VoidCallback? onNegative, KitStrings? strings, required void Function(bool) result}) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => result(await showReviewPrePrompt(context, s, onNegative: onNegative, strings: strings)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('条件を満たさなければ、何も出さない', (tester) async {
      final (s, backend, _, _) = await _make();
      bool? shown;
      await open(tester, s, result: (v) => shown = v);
      expect(shown, isFalse);
      expect(find.text('アプリを楽しんでいますか？'), findsNothing);
      expect(backend.requestCount, 0);
    });

    testWidgets('「はい」でレビュー画面を出す', (tester) async {
      final (s, backend, clock, _) = await _make();
      await _ready(s, clock);
      bool? shown;
      await open(tester, s, result: (v) => shown = v);
      expect(find.text('アプリを楽しんでいますか？'), findsOneWidget);
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();
      expect(shown, isTrue);
      expect(backend.requestCount, 1);
    });

    testWidgets('「いいえ」ではレビューを頼まず、フィードバックへ案内でき、しばらく控える', (tester) async {
      final (s, backend, clock, _) = await _make();
      await _ready(s, clock);
      var negative = 0;
      await open(tester, s, onNegative: () => negative++, result: (_) {});
      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();
      expect(negative, 1);
      expect(backend.requestCount, 0);
      expect(s.evaluate(), ReviewDecision.declinedRecently);
    });

    testWidgets('「あとで」・枠外タップでは、頼んだことにも断られたことにもならない', (tester) async {
      final (s, backend, clock, _) = await _make();
      await _ready(s, clock);
      await open(tester, s, result: (_) {});
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();
      expect(backend.requestCount, 0);
      expect(s.evaluate(), ReviewDecision.ask);

      await open(tester, s, result: (_) {});
      await tester.tapAt(const Offset(5, 5)); // 枠の外
      await tester.pumpAndSettle();
      expect(s.evaluate(), ReviewDecision.ask);
      expect(s.state.askCount, 0);
    });

    testWidgets('英語で出せる', (tester) async {
      final (s, _, clock, _) = await _make();
      await _ready(s, clock);
      await open(tester, s, strings: KitStrings.en, result: (_) {});
      expect(find.text('Are you enjoying the app?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Not really'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });
  });
}
