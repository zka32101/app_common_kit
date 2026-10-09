import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HandsFreeSettings', () {
    test('既定は無効。JSON で往復できる', () {
      expect(const HandsFreeSettings().enabled, isFalse);

      const s = HandsFreeSettings(enabled: true, speakQuestion: false, speechRate: 1.25);

      expect(HandsFreeSettings.fromJson(s.toJson()), s);
    });

    test('壊れた・欠けた保存データは、読めた項目だけを使い残りは既定値', () {
      final s = HandsFreeSettings.fromJson({
        'enabled': 'yes',
        'speakQuestion': false,
        'speechRate': 'fast',
      });

      expect(s.enabled, isFalse);
      expect(s.speakQuestion, isFalse);
      expect(s.speakExplanation, isTrue);
      expect(s.speechRate, 1.0);
      expect(HandsFreeSettings.fromJson(null), const HandsFreeSettings());
    });

    test('読み上げの速さは 0.5〜1.5 に収める', () {
      expect(HandsFreeSettings.fromJson({'speechRate': 9}).speechRate, 1.5);
      expect(HandsFreeSettings.fromJson({'speechRate': 0.1}).speechRate, 0.5);
      expect(const HandsFreeSettings().copyWith(speechRate: 3).speechRate, 1.5);
    });
  });

  group('HandsFreeNotifier', () {
    test('設定を変えると保存され、load で復元できる', () async {
      final store = InMemoryHandsFreeStore();
      final container = ProviderContainer(overrides: [
        handsFreeStoreProvider.overrideWithValue(store),
      ]);
      addTearDown(container.dispose);

      await container.read(handsFreeProvider.notifier).setEnabled(true);
      await container.read(handsFreeProvider.notifier).setSpeechRate(0.8);

      final restored = ProviderContainer(overrides: [
        handsFreeStoreProvider.overrideWithValue(store),
      ]);
      addTearDown(restored.dispose);
      expect(restored.read(handsFreeProvider).enabled, isFalse);
      await restored.read(handsFreeProvider.notifier).load();
      expect(restored.read(handsFreeProvider).enabled, isTrue);
      expect(restored.read(handsFreeProvider).speechRate, 0.8);
    });
  });

  group('読み上げ', () {
    test('questionReadAloudText: 問題文と選択肢をアイウエの順に読む', () {
      expect(
        questionReadAloudText('1+1は？', ['1', '2']),
        '問題。1+1は？。選択肢。ア、1。イ、2。',
      );
      expect(questionReadAloudText('自由記述', const []), '問題。自由記述。');
    });

    test('ラベルが足りない選択肢は数字で読む', () {
      final text = questionReadAloudText('q', List.generate(9, (i) => 'c$i'));

      expect(text, contains('9、c8。'));
    });

    test('モードが無効なら自動では読まない', () async {
      final backend = FakeSpeechBackend();
      final speaker = HandsFreeSpeaker(backend: backend, settings: () => const HandsFreeSettings());

      expect(await speaker.readQuestion('問題', ['a']), isFalse);
      expect(await speaker.readExplanation('解説'), isFalse);
      expect(backend.spoken, isEmpty);
    });

    test('有効なら、問題と解説をそれぞれのオン・オフに従って読む。速さも渡す', () async {
      final backend = FakeSpeechBackend();
      var settings = const HandsFreeSettings(enabled: true, speechRate: 1.2);
      final speaker = HandsFreeSpeaker(backend: backend, settings: () => settings);

      expect(await speaker.readQuestion('問題', ['a', 'b']), isTrue);
      expect(await speaker.readExplanation('解説'), isTrue);
      expect(backend.spoken, ['問題。問題。選択肢。ア、a。イ、b。', '解説']);
      expect(backend.rates, [1.2, 1.2]);

      settings = settings.copyWith(speakQuestion: false);
      expect(await speaker.readQuestion('問題', ['a']), isFalse);
      expect(backend.spoken.length, 2);
    });

    test('読み上げボタンは、モードが無効でも読む。空の文は読まない', () async {
      final backend = FakeSpeechBackend();
      final speaker = HandsFreeSpeaker(backend: backend, settings: () => const HandsFreeSettings());

      expect(await speaker.speakNow('テスト'), isTrue);
      expect(await speaker.speakNow('  '), isFalse);
      expect(backend.spoken, ['テスト']);
    });

    test('読み上げに失敗しても例外を出さない', () async {
      final speaker = HandsFreeSpeaker(backend: _ThrowingBackend(), settings: () => const HandsFreeSettings(enabled: true));

      expect(await speaker.readQuestion('問題', ['a']), isFalse);
      await speaker.stop();
    });
  });

  group('画面部品', () {
    testWidgets('HandsFreeChoiceTile は高さ 72pt 以上で、タップできる', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: HandsFreeChoiceTile(
              label: 'ア',
              text: '選択肢',
              state: ChoiceState.idle,
              onTap: () => tapped++,
            ),
          ),
        ),
      ));

      expect(tester.getSize(find.byType(HandsFreeChoiceTile)).height >= 72, isTrue);
      await tester.tap(find.byType(HandsFreeChoiceTile));
      expect(tapped, 1);
    });

    testWidgets('正解・不正解は文言も出す（色だけに頼らない）', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Column(children: [
            HandsFreeChoiceTile(label: 'ア', text: 'a', state: ChoiceState.correct),
            HandsFreeChoiceTile(label: 'イ', text: 'b', state: ChoiceState.incorrect),
          ]),
        ),
      ));

      expect(find.text('正解'), findsOneWidget);
      expect(find.text('不正解'), findsOneWidget);
    });

    testWidgets('HandsFreeQuestionLayout は選択肢を画面の下に寄せる', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HandsFreeQuestionLayout(
            question: const Text('問題文'),
            choices: const [
              HandsFreeChoiceTile(label: 'ア', text: 'a', state: ChoiceState.idle),
              HandsFreeChoiceTile(label: 'イ', text: 'b', state: ChoiceState.idle),
            ],
            trailing: ReadAloudButton(onPressed: () {}),
          ),
        ),
      ));

      final screen = tester.getSize(find.byType(Scaffold));
      final question = tester.getTopLeft(find.text('問題文'));
      final lastChoice = tester.getBottomLeft(find.byType(HandsFreeChoiceTile).last);

      expect(question.dy < screen.height / 2, isTrue);
      expect(lastChoice.dy > screen.height * 0.8, isTrue);
    });

    testWidgets('ReadAloudButton はタップできる', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: ReadAloudButton(onPressed: () => tapped++))),
      ));

      await tester.tap(find.byType(ReadAloudButton));
      expect(tapped, 1);
    });
  });
}

class _ThrowingBackend implements SpeechBackend {
  @override
  Future<void> speak(String text, {double rate = 1.0}) async => throw Exception('no tts');

  @override
  Future<void> stop() async => throw Exception('no tts');
}
