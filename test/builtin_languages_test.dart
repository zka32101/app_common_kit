import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final builtIn = {
    'ja': KitStrings.ja,
    'en': KitStrings.en,
    'zh': KitStrings.zhHans,
    'zh-Hant': KitStrings.zhHant,
    'ko': KitStrings.ko,
  };

  group('forLocale', () {
    test('内蔵の言語を選ぶ', () {
      expect(KitStrings.forLocale(const Locale('ja')), same(KitStrings.ja));
      expect(KitStrings.forLocale(const Locale('en', 'US')), same(KitStrings.en));
      expect(KitStrings.forLocale(const Locale('ko', 'KR')), same(KitStrings.ko));
      expect(KitStrings.forLocale(const Locale('zh')), same(KitStrings.zhHans));
      expect(KitStrings.forLocale(const Locale('zh', 'CN')), same(KitStrings.zhHans));
      expect(KitStrings.forLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')), same(KitStrings.zhHans));
    });

    test('繁体字は、スクリプト指定か、台湾・香港・マカオ', () {
      expect(KitStrings.forLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')), same(KitStrings.zhHant));
      expect(KitStrings.forLocale(const Locale('zh', 'TW')), same(KitStrings.zhHant));
      expect(KitStrings.forLocale(const Locale('zh', 'HK')), same(KitStrings.zhHant));
      expect(KitStrings.forLocale(const Locale('zh', 'MO')), same(KitStrings.zhHant));
      // スクリプトが簡体字なら、国が台湾でも簡体字
      expect(KitStrings.forLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'TW')), same(KitStrings.zhHans));
    });

    test('未対応の言語は日本語。アプリが渡した言語は内蔵より優先', () {
      expect(KitStrings.forLocale(const Locale('fr')), same(KitStrings.ja));
      final myKo = KitStrings.ko.copyWith(close: 'X');
      expect(KitStrings.forLocale(const Locale('ko'), supported: {'ko': myKo}), same(myKo));
    });
  });

  group('内蔵の言語はそろっている', () {
    for (final e in builtIn.entries) {
      final s = e.value;
      test('${e.key}: languageCode が合っている', () {
        expect(s.languageCode, e.key);
      });

      test('${e.key}: 文言が空でない', () {
        final texts = <String>[
          s.reviewEnjoyTitle, s.updateRequiredTitle, s.updateRequiredBody, s.updateAvailableTitle, s.updateAvailableBody,
          s.updateNow, s.updateLater, s.reviewYes, s.reviewNo, s.reviewLater, s.purchaseTitle, s.purchasedPremium,
          s.purchasedNoAds, s.purchaseRestore, s.purchaseSuccess, s.purchaseCancelled, s.purchaseBlocked,
          s.purchaseFailed, s.restoreDone, s.restoreNone, s.examDateTitle, s.examDateUnset, s.examDateClear,
          s.settingsTitle, s.settingsTheme, s.themeSystem, s.themeLight, s.themeDark, s.settingsLanguage,
          s.settingsHandsFree, s.handsFreeEnable, s.handsFreeSpeakQuestion, s.handsFreeSpeakExplanation,
          s.handsFreeSpeed, s.settingsTransfer, s.settingsAbout, s.coinTotal, s.coinBreakdownTitle, s.errorMessage,
          s.retry, s.streakZero, s.accuracy, s.passLineReached, s.passLineNotYet, s.again, s.close,
          s.feedbackTitle, s.feedbackType, s.feedbackBug, s.feedbackFeature, s.feedbackOther, s.feedbackSubject,
          s.feedbackSubjectHint, s.feedbackDetail, s.feedbackDetailHint, s.feedbackSubmit, s.feedbackSent,
          s.feedbackFailed, s.correctLabel, s.incorrectLabel, s.explanationTitle, s.readAloud,
          ...s.tabLabels,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty);
        }
      });

      test('${e.key}: コインの種類と推しの役割が、日本語と同じキーを全部持つ', () {
        expect(s.coinEventLabels.keys.toSet(), KitStrings.ja.coinEventLabels.keys.toSet());
        expect(s.characterRoles.keys.toSet(), KitStrings.ja.characterRoles.keys.toSet());
        expect(s.tabLabels.length, 5);
        for (final v in [...s.coinEventLabels.values, ...s.characterRoles.values]) {
          expect(v.trim(), isNotEmpty);
        }
      });

      test('${e.key}: 値を埋め込む文言に、値が入る', () {
        expect(s.aboutVersion('1.2.3'), contains('1.2.3'));
        expect(s.streakDays(7), contains('7'));
        expect(s.streakSemantics(7), contains('7'));
        expect(s.correctOfTotal(8, 10), allOf(contains('8'), contains('10')));
        expect(s.passLine(70), contains('70'));
        expect(s.coinBalance(120), contains('120'));
        expect(s.wardrobePurchased('帽子'), contains('帽子'));
        expect(s.wardrobePrice(300), contains('300'));
        expect(s.lockedNotPurchased(300), contains('300'));
        expect(s.passAskTitle('G検定'), contains('G検定'));
        expect(s.passCoin(50), contains('50'));
        expect(s.passOutfit('帽子'), contains('帽子'));
        expect(s.feedbackTitleTooLong(80), contains('80'));
        expect(s.feedbackDetailTooLong(1000), contains('1000'));
        expect(s.sourceNote('第1条'), contains('第1条'));
        expect(s.sourceNoteChecked('第1条', '2026-10-09'), allOf(contains('第1条'), contains('2026-10-09')));
        expect(s.mockRecordCert('G検定'), contains('G検定'));
        final d = s.shareDate(DateTime(2026, 10, 9));
        expect(d, allOf(contains('2026'), contains('9')));
      });
    }

    test('日本語の文字が、他の言語の文言に混ざっていない（かな）', () {
      // 中黒(U+30FB)と長音(U+30FC)は中国語・韓国語でも使うので除く。
      final kana = RegExp(r'[\u3040-\u309F\u30A0-\u30FA\u30FD-\u30FF]');
      for (final e in builtIn.entries.where((e) => e.key != 'ja')) {
        final s = e.value;
        final all = <String>[
          s.reviewEnjoyTitle, s.updateRequiredBody, s.settingsHandsFree, s.examDateUnset, s.passEncourageBody,
          s.wardrobeNote, s.feedbackFailed, s.oshiTapHint, s.mockRecordNote, s.errorMessage,
          ...s.coinEventLabels.values, ...s.characterRoles.values, ...s.tabLabels,
          s.streakDays(3), s.passLine(70), s.shareDate(DateTime(2026, 10, 9)),
        ];
        for (final t in all) {
          expect(kana.hasMatch(t), isFalse, reason: '${e.key}: 「$t」にかなが混ざっている');
        }
      }
    });
  });

  testWidgets('ScopeにKoを渡すと、画面の文言が韓国語になる', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: KitStringsScope(
        strings: KitStrings.ko,
        child: Builder(builder: (c) => Text(KitStrings.of(c).settingsTitle)),
      ),
    ));
    expect(find.text('설정'), findsOneWidget);
  });
}
