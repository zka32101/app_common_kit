import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {KitStrings? strings}) =>
    MaterialApp(
      home: KitStringsScope(
        strings: strings ?? KitStrings.ja,
        child: Scaffold(body: child),
      ),
    );

void main() {
  // copyWith に項目を足し忘れると、コンストラクタの必須引数が足りずコンパイルエラーになる。
  group('copyWith', () {
    test('指定した項目だけ変わり、ほかは元のまま', () {
      final k = KitStrings.en.copyWith(languageCode: 'zh', close: '关闭');
      expect(k.languageCode, 'zh');
      expect(k.close, '关闭');
      expect(k.retry, KitStrings.en.retry);
      expect(k.streakDays(3), KitStrings.en.streakDays(3));
      expect(KitStrings.en.languageCode, 'en'); // 元は変わらない

      final q = KitStrings.en.copyWith(progressDefault: '进度');
      expect(q.progressDefault, '进度');
      expect(q.questionNo(2), KitStrings.en.questionNo(2));
    });
  });

  group('forLocale', () {
    final zh = KitStrings.en.copyWith(languageCode: 'zh', close: '关闭');

    test('アプリが用意した言語を選べる。内蔵に無い言語は従来どおり日本語', () {
      final supported = {'zh': zh};
      expect(KitStrings.forLocale(const Locale('zh', 'CN'), supported: supported), same(zh));
      expect(KitStrings.forLocale(const Locale('en'), supported: supported), same(KitStrings.en));
      expect(KitStrings.forLocale(const Locale('fr'), supported: supported), same(KitStrings.ja));
      expect(KitStrings.forLocale(const Locale('zh')), same(KitStrings.zhHans)); // 中国語は内蔵（v1.3.0〜）
      expect(KitStrings.forLocale(const Locale('vi')), same(KitStrings.ja)); // 内蔵に無く、渡さなければ日本語
    });

    test('supported で ja/en を上書きもできる', () {
      final custom = KitStrings.en.copyWith(close: 'Sum');
      expect(KitStrings.forLocale(const Locale('en'), supported: {'en': custom}), same(custom));
    });
  });

  group('Scope', () {
    testWidgets('追加した言語の文言が画面に出る', (tester) async {
      final zh = KitStrings.en.copyWith(languageCode: 'zh', retry: '再试一次');
      await tester.pumpWidget(_app(ErrorState(onRetry: () {}), strings: zh));
      expect(find.text('再试一次'), findsOneWidget);
    });
  });
}

