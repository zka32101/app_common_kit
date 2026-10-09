import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const limits = FeedbackLimits();

  group('FeedbackLimits', () {
    test('空・空白のみはエラー', () {
      expect(limits.validateTitle('  '), isNotNull);
      expect(limits.validateDescription(null), isNotNull);
    });

    test('文字数の境界', () {
      expect(limits.validateTitle('a' * 100), isNull);
      expect(limits.validateTitle('a' * 101), isNotNull);
      expect(limits.validateDescription('a' * 2000), isNull);
      expect(limits.validateDescription('a' * 2001), isNotNull);
    });
    test('英語の文言で返せる', () {
      expect(limits.validateTitle('', KitStrings.en), 'Please enter a title');
      expect(limits.validateTitle('a' * 101, KitStrings.en),
          'Title must be 100 characters or fewer');
      expect(limits.validateTitle('', KitStrings.ja), 'タイトルを入力してください');
    });
  });

  group('FeedbackNotifier', () {
    late ProviderContainer container;
    late DateTime now;
    late List<FeedbackReport> sent;

    FeedbackNotifier notifier() => container.read(feedbackProvider.notifier);

    Future<void> submit([String title = 't', String desc = 'd']) =>
        notifier().submitFeedback(
          type: FeedbackType.bug,
          title: title,
          description: desc,
          appName: 'test',
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 10, 2, 9);
      sent = [];
      container = ProviderContainer();
      notifier()
        ..configure(clock: () => now)
        ..setSubmitHandler((r) async => sent.add(r));
    });

    tearDown(() => container.dispose());

    test('不正な入力は送信されずエラーになる', () async {
      await submit('', 'd');
      expect(container.read(feedbackProvider).status, FeedbackSubmitStatus.error);
      expect(sent, isEmpty);
    });

    test('1日の上限を超えると送信されず、翌日は再び送れる', () async {
      for (var i = 0; i < 5; i++) {
        await submit();
      }
      expect(sent.length, 5);
      await submit();
      expect(sent.length, 5);
      expect(container.read(feedbackProvider).status, FeedbackSubmitStatus.error);

      now = DateTime(2026, 10, 3, 0, 1);
      await submit();
      expect(sent.length, 6);
      expect(container.read(feedbackProvider).status, FeedbackSubmitStatus.success);
    });

    test('前後の空白は除去して送信される', () async {
      await submit('  題名  ', '  本文  ');
      expect(sent.single.title, '題名');
      expect(sent.single.description, '本文');
    });
  });

  testWidgets('お問い合わせ画面が文字拡大2.0でも例外なく表示される', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const FeedbackFormPage(appName: 'test'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
