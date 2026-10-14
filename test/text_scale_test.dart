import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appTextScale.value = AppTextScale.standard;
  });

  test('保存して復元できる。未保存・不正値は標準', () async {
    await setTextScale(AppTextScale.large);
    appTextScale.value = AppTextScale.standard;
    await loadSavedTextScale();
    expect(appTextScale.value, AppTextScale.large);

    SharedPreferences.setMockInitialValues({
      'app_common_kit_text_scale': 'bogus',
    });
    await loadSavedTextScale();
    expect(appTextScale.value, AppTextScale.standard);
  });

  test('clearSavedTextScale は標準に戻して保存も消す', () async {
    await setTextScale(AppTextScale.xLarge);
    await clearSavedTextScale();
    expect(appTextScale.value, AppTextScale.standard);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'app_common_kit_text_scale',
      ),
      isNull,
    );
  });

  testWidgets('端末の文字サイズに掛け合わせる', (tester) async {
    double? seen;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: applyAppTextScale(context, child),
        ),
        home: Builder(
          builder: (c) {
            seen = MediaQuery.of(c).textScaler.scale(10) / 10;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, closeTo(1.5, 0.001));
    appTextScale.value = AppTextScale.xLarge;
    await tester.pump();
    expect(seen, closeTo(1.5 * 1.3, 0.001));
  });

  testWidgets('選択すると反映して保存する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        home: Scaffold(body: TextScaleSetting(strings: TextScaleStrings.ja)),
      ),
    );
    await tester.tap(find.text('特大'));
    await tester.pumpAndSettle();
    expect(appTextScale.value, AppTextScale.xLarge);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'app_common_kit_text_scale',
      ),
      'xLarge',
    );
  });
}
