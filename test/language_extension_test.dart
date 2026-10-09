import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {KitStrings? strings, LabStrings? labs, Map<MascotTone, MascotLines>? lines}) =>
    MaterialApp(
      home: KitStringsScope(
        strings: strings ?? KitStrings.ja,
        labs: labs,
        mascotLines: lines,
        child: Scaffold(body: child),
      ),
    );

void main() {
  // copyWith に項目を足し忘れると、コンストラクタの必須引数が足りずコンパイルエラーになる。
  group('copyWith', () {
    test('指定した項目だけ変わり、ほかは元のまま', () {
      final k = KitStrings.en.copyWith(languageCode: 'zh', coinTotal: '合计');
      expect(k.languageCode, 'zh');
      expect(k.coinTotal, '合计');
      expect(k.coinBreakdownTitle, KitStrings.en.coinBreakdownTitle);
      expect(k.streakDays(3), KitStrings.en.streakDays(3));
      expect(KitStrings.en.languageCode, 'en'); // 元は変わらない

      final l = LabStrings.en.copyWith(progressDefault: '进度');
      expect(l.progressDefault, '进度');
      expect(l.gotIt, LabStrings.en.gotIt);
    });
  });

  group('forLocale', () {
    final zh = KitStrings.en.copyWith(languageCode: 'zh', coinTotal: '合计');

    test('アプリが用意した言語を選べる。無い言語は従来どおり（en→英語、他→日本語）', () {
      final supported = {'zh': zh};
      expect(KitStrings.forLocale(const Locale('zh', 'CN'), supported: supported), same(zh));
      expect(KitStrings.forLocale(const Locale('en'), supported: supported), same(KitStrings.en));
      expect(KitStrings.forLocale(const Locale('fr'), supported: supported), same(KitStrings.ja));
      expect(KitStrings.forLocale(const Locale('zh')), same(KitStrings.ja)); // 渡さなければ日本語
    });

    test('supported で ja/en を上書きもできる', () {
      final custom = KitStrings.en.copyWith(coinTotal: 'Sum');
      expect(KitStrings.forLocale(const Locale('en'), supported: {'en': custom}), same(custom));
    });
  });

  group('Scope', () {
    testWidgets('追加した言語の文言が画面に出る', (tester) async {
      final zh = KitStrings.en.copyWith(languageCode: 'zh', streakZero: '今天开始吧');
      await tester.pumpWidget(_app(const StreakBadge(days: 0), strings: zh));
      expect(find.text('今天开始吧'), findsOneWidget);
    });

    testWidgets('labs を渡せばラボ系の文言も差し替わる。渡さなければ言語に応じた既定', (tester) async {
      Widget probe() => Builder(builder: (c) => Text(LabStrings.of(c).progressDefault));
      final zh = KitStrings.en.copyWith(languageCode: 'zh');

      // 渡さない: zh は en ではないので日本語の既定
      await tester.pumpWidget(_app(probe(), strings: zh));
      expect(find.text(LabStrings.ja.progressDefault), findsOneWidget);

      // 渡す
      await tester.pumpWidget(_app(probe(), strings: zh, labs: LabStrings.en.copyWith(progressDefault: '进度')));
      expect(find.text('进度'), findsOneWidget);

      // en は従来どおり英語
      await tester.pumpWidget(_app(probe(), strings: KitStrings.en));
      expect(find.text(LabStrings.en.progressDefault), findsOneWidget);
    });

    testWidgets('mascotLines を渡せば推しのセリフが差し替わる', (tester) async {
      final lines = {
        MascotTone.gentle: const MascotLines({
          MascotSituation.greeting: ['你好'],
        }),
      };
      late MascotLines resolved;
      await tester.pumpWidget(_app(
        Builder(builder: (c) {
          resolved = MascotLines.forTone(MascotTone.gentle, custom: KitStringsScope.mascotLinesOf(c));
          return const SizedBox();
        }),
        lines: lines,
      ));
      expect(resolved.pick(MascotSituation.greeting), '你好');
      // 渡さなければ既定
      expect(MascotLines.forTone(MascotTone.gentle).pick(MascotSituation.greeting), isNot('你好'));
    });
  });
}
