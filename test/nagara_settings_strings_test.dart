import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HandsFreeSettings（ながらセッションの項目）', () {
    test('既定値', () {
      const s = HandsFreeSettings();
      expect(s.thinkSeconds, 5);
      expect(s.betweenSeconds, 2);
      expect(s.autoAdvance, isTrue);
    });

    test('旧データ（新しいキーなし）は既定値で読み込み、既存の値は壊さない', () {
      final s = HandsFreeSettings.fromJson({
        'enabled': true,
        'speakQuestion': false,
        'speakExplanation': false,
        'speechRate': 1.25,
      });
      expect(s.enabled, isTrue);
      expect(s.speakQuestion, isFalse);
      expect(s.speakExplanation, isFalse);
      expect(s.speechRate, 1.25);
      expect(s.thinkSeconds, 5);
      expect(s.betweenSeconds, 2);
      expect(s.autoAdvance, isTrue);
    });

    test('新しいキーで往復でき、旧キーも書き出し続ける', () {
      const s = HandsFreeSettings(thinkSeconds: 12, betweenSeconds: 5, autoAdvance: false);
      expect(HandsFreeSettings.fromJson(s.toJson()), s);
      expect(s.toJson().keys, containsAll(['enabled', 'speakQuestion', 'speakExplanation', 'speechRate']));
    });

    test('壊れた値は既定値、範囲外は収める', () {
      final bad = HandsFreeSettings.fromJson({'thinkSeconds': 'x', 'betweenSeconds': null, 'autoAdvance': 1});
      expect(bad.thinkSeconds, 5);
      expect(bad.betweenSeconds, 2);
      expect(bad.autoAdvance, isTrue);
      final far = HandsFreeSettings.fromJson({'thinkSeconds': 999, 'betweenSeconds': -4});
      expect(far.thinkSeconds, 30);
      expect(far.betweenSeconds, 0);
      expect(const HandsFreeSettings().copyWith(thinkSeconds: 0).thinkSeconds, 1);
      expect(const HandsFreeSettings().copyWith(betweenSeconds: 99).betweenSeconds, 10);
    });

    test('候補の値は範囲内', () {
      for (final v in HandsFreeSettings.thinkSecondsOptions) {
        expect(v, inInclusiveRange(HandsFreeSettings.minThinkSeconds, HandsFreeSettings.maxThinkSeconds));
      }
      for (final v in HandsFreeSettings.betweenSecondsOptions) {
        expect(v, inInclusiveRange(HandsFreeSettings.minBetweenSeconds, HandsFreeSettings.maxBetweenSeconds));
      }
    });

    test('Notifier で変えると保存され、load で復元できる', () async {
      final store = InMemoryHandsFreeStore();
      final c = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      final n = c.read(handsFreeProvider.notifier);
      await n.setThinkSeconds(8);
      await n.setBetweenSeconds(3);
      await n.setAutoAdvance(false);
      final c2 = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
      addTearDown(c2.dispose);
      await c2.read(handsFreeProvider.notifier).load();
      final s = c2.read(handsFreeProvider);
      expect((s.thinkSeconds, s.betweenSeconds, s.autoAdvance), (8, 3, false));
    });

    test('旧形式の保存データを Store から読んでも壊れない', () async {
      final store = InMemoryHandsFreeStore();
      await store.write({'enabled': true, 'speakQuestion': true, 'speakExplanation': true, 'speechRate': 1.0});
      final c = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      await c.read(handsFreeProvider.notifier).load();
      expect(c.read(handsFreeProvider), const HandsFreeSettings(enabled: true));
    });
  });

  group('文言', () {
    List<String> all(NagaraStrings t) => [
          t.positionLabel(3, 10),
          t.remainingLabel(7),
          t.phaseReadingQuestion,
          t.phaseWaitingAnswer,
          t.phaseReadingAnswer,
          t.phasePausedBetween,
          t.phasePaused,
          t.phaseFinished,
          t.pause,
          t.resume,
          t.skip,
          t.stop,
          t.close,
          t.tapHint,
          t.speechUnavailable,
          t.chosenLabel,
          t.correctSpoken,
          t.checkSpoken,
          t.unansweredSpoken,
          t.answerIsSpoken('ア', 'こたえ'),
          t.explanationSpoken,
          t.finishedSummary(7, 10),
          t.restSuggestion,
          t.settingsThinkSeconds,
          t.settingsBetweenSeconds,
          t.settingsAutoAdvance,
          t.secondsOption(5),
        ];

    test('日本語に禁止語（責める・急かす言い方）を含まない', () {
      const banned = [
        'サボ', 'さぼ', '遅れ', '遅い', 'しないと', 'ダメ', 'だめ', '焦', '急が', '急い', '早く',
        '間違', 'まちが', '失敗', '不正解', '残念', 'できない',
      ];
      for (final text in all(NagaraStrings.ja)) {
        expect(text, isNotEmpty);
        for (final w in banned) {
          expect(text.contains(w), isFalse, reason: '「$text」に禁止語「$w」');
        }
      }
    });

    test('英語に禁止語を含まない', () {
      final banned = RegExp(
        r'\b(wrong|late|behind|hurry|quick(ly)?|lazy|fail(ed|ure)?|mistakes?|bad|must|slow|incorrect)\b',
        caseSensitive: false,
      );
      for (final text in all(NagaraStrings.en)) {
        expect(text, isNotEmpty);
        expect(banned.hasMatch(text), isFalse, reason: '「$text」に禁止語');
      }
    });

    test('KitStrings から引け、省略すると日本語。copyWith で差し替えられる', () {
      expect(KitStrings.ja.nagara, same(NagaraStrings.ja));
      expect(KitStrings.en.nagara, same(NagaraStrings.en));
      expect(KitStrings.ko.nagara, same(NagaraStrings.ja));
      expect(KitStrings.en.copyWith(languageCode: 'x').nagara, same(NagaraStrings.en));
      expect(KitStrings.ja.copyWith(nagara: NagaraStrings.en).nagara, same(NagaraStrings.en));
    });
  });
}
