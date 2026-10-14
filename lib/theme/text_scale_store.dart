import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_store.dart';

/// アプリ内の文字サイズ。端末の文字サイズ設定に**掛け合わせる**（端末側の拡大は消さない）。
enum AppTextScale {
  standard(1.0),
  large(1.15),
  xLarge(1.3);

  const AppTextScale(this.factor);

  final double factor;
}

/// 現在のアプリ内文字サイズ。[applyAppTextScale] がリッスンして全画面に反映する。
final ValueNotifier<AppTextScale> appTextScale = ValueNotifier<AppTextScale>(
  AppTextScale.standard,
);

const _textScaleKey = 'app_common_kit_text_scale';

/// 起動時に `SharedPreferences` から復元する。`runApp` より前に呼ぶ想定。
Future<void> loadSavedTextScale() async {
  final saved = (await SharedPreferences.getInstance()).getString(
    _textScaleKey,
  );
  appTextScale.value = AppTextScale.values.firstWhere(
    (s) => s.name == saved,
    orElse: () => AppTextScale.standard,
  );
}

/// 文字サイズを変更し、端末内に保存する。
Future<void> setTextScale(AppTextScale scale) async {
  appTextScale.value = scale;
  await (await SharedPreferences.getInstance()).setString(
    _textScaleKey,
    scale.name,
  );
}

/// 保存した文字サイズを消す（データ削除用）。標準に戻る。
Future<void> clearSavedTextScale() async {
  appTextScale.value = AppTextScale.standard;
  await (await SharedPreferences.getInstance()).remove(_textScaleKey);
}

/// `MaterialApp(builder: applyAppTextScale)` に渡す。端末の文字サイズに [appTextScale] を掛ける。
Widget applyAppTextScale(BuildContext context, Widget? child) {
  return ValueListenableBuilder<AppTextScale>(
    valueListenable: appTextScale,
    builder: (context, scale, _) {
      final mq = MediaQuery.of(context);
      if (scale == AppTextScale.standard)
        return child ?? const SizedBox.shrink();
      // 端末の拡大率（非線形でも 14pt 基準で近似）に掛ける。
      final system = mq.textScaler.scale(14) / 14;
      return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(system * scale.factor)),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

/// 文字サイズ選択の文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き）。
class TextScaleStrings {
  const TextScaleStrings({
    required this.title,
    required this.standard,
    required this.large,
    required this.xLarge,
  });

  final String title;
  final String standard;
  final String large;
  final String xLarge;

  static const ja = TextScaleStrings(
    title: '文字の大きさ',
    standard: '標準',
    large: '大',
    xLarge: '特大',
  );
  static const en = TextScaleStrings(
    title: 'Text size',
    standard: 'Standard',
    large: 'Large',
    xLarge: 'Extra large',
  );
  static const zh = TextScaleStrings(
    title: '文字大小',
    standard: '标准',
    large: '大',
    xLarge: '特大',
  );
  static const zhHant = TextScaleStrings(
    title: '文字大小',
    standard: '標準',
    large: '大',
    xLarge: '特大',
  );
  static const ko = TextScaleStrings(
    title: '글자 크기',
    standard: '표준',
    large: '크게',
    xLarge: '매우 크게',
  );

  /// `ja` / `en` / `zh` / `zh-Hant` / `ko`。それ以外は英語。
  static TextScaleStrings forCode(String code) => switch (code) {
    'ja' => ja,
    'zh' => zh,
    'zh-Hant' => zhHant,
    'ko' => ko,
    _ => en,
  };

  static TextScaleStrings forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return ja;
      case 'zh':
        return locale.scriptCode == 'Hant' ||
                locale.countryCode == 'TW' ||
                locale.countryCode == 'HK'
            ? zhHant
            : zh;
      case 'ko':
        return ko;
      default:
        return en;
    }
  }

  String labelOf(AppTextScale s) => switch (s) {
    AppTextScale.standard => standard,
    AppTextScale.large => large,
    AppTextScale.xLarge => xLarge,
  };
}

/// 設定画面に置く文字サイズの選択。選ぶと即反映して保存する。
class TextScaleSetting extends StatelessWidget {
  const TextScaleSetting({super.key, this.strings});

  final TextScaleStrings? strings;

  @override
  Widget build(BuildContext context) {
    final s =
        strings ?? TextScaleStrings.forLocale(Localizations.localeOf(context));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ValueListenableBuilder<AppTextScale>(
            valueListenable: appTextScale,
            builder: (context, current, _) => SegmentedButton<AppTextScale>(
              segments: [
                for (final v in AppTextScale.values)
                  ButtonSegment(value: v, label: Text(s.labelOf(v))),
              ],
              selected: {current},
              onSelectionChanged: (v) => setTextScale(v.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// 起動時に、キットが持つ端末内の設定（表示モード・文字サイズ）をまとめて読み込む。`runApp` より前に呼ぶ。
Future<void> loadKitPreferences() async {
  await loadSavedThemeMode();
  await loadSavedTextScale();
}
