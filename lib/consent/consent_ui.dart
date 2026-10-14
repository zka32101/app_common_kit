import 'package:flutter/material.dart';

import 'consent.dart';

/// 同意の画面の文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き。公開前に母語話者の確認が要る）。
///
/// 文面は一般的な説明。実際に取得するデータと、法域ごとの要件に合わせて、専門家の確認を経て使う。
class ConsentStrings {
  const ConsentStrings({
    required this.menu,
    required this.promptTitle,
    required this.promptBody,
    required this.acceptAll,
    required this.declineAll,
    required this.customize,
    required this.settingsTitle,
    required this.settingsBody,
    required this.close,
    required this.analyticsTitle,
    required this.analyticsBody,
    required this.crashTitle,
    required this.crashBody,
    required this.adsTitle,
    required this.adsBody,
  });

  final String menu;
  final String promptTitle;
  final String promptBody;
  final String acceptAll;
  final String declineAll;
  final String customize;
  final String settingsTitle;
  final String settingsBody;
  final String close;
  final String analyticsTitle;
  final String analyticsBody;
  final String crashTitle;
  final String crashBody;
  final String adsTitle;
  final String adsBody;

  String titleOf(ConsentCategory c) => switch (c) {
        ConsentCategory.analytics => analyticsTitle,
        ConsentCategory.crashReports => crashTitle,
        ConsentCategory.personalizedAds => adsTitle,
      };

  String bodyOf(ConsentCategory c) => switch (c) {
        ConsentCategory.analytics => analyticsBody,
        ConsentCategory.crashReports => crashBody,
        ConsentCategory.personalizedAds => adsBody,
      };

  /// `KitStrings.languageCode`（`ja`・`en`・`zh`・`zh-Hant`・`ko`）に合わせて選ぶ。それ以外は日本語。
  static ConsentStrings forCode(String code) => switch (code) {
        'en' => en,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        'ko' => ko,
        _ => ja,
      };

  static const ja = ConsentStrings(
    menu: 'プライバシーの設定',
    promptTitle: 'データの利用について',
    promptBody: 'アプリの改善のため、利用状況やエラーの情報を集めることがあります。個人を特定する情報は含めません。同意しなくても、アプリはすべて使えます。あとから設定で変えられます。',
    acceptAll: 'すべて同意する',
    declineAll: '同意しない',
    customize: '項目ごとに選ぶ',
    settingsTitle: 'プライバシーの設定',
    settingsBody: '項目ごとに、オンとオフを選べます。',
    close: '閉じる',
    analyticsTitle: '利用状況の分析',
    analyticsBody: '機能がどのくらい使われているかを集計します。',
    crashTitle: 'エラーの送信',
    crashBody: 'アプリが止まったときの情報を送り、不具合の修正に使います。',
    adsTitle: 'パーソナライズ広告',
    adsBody: 'オフにすると、興味に合わせない広告が表示されます。',
  );
  static const en = ConsentStrings(
    menu: 'Privacy settings',
    promptTitle: 'About your data',
    promptBody:
        'To improve the app, we may collect usage and error information. It does not include information that identifies you. You can use the whole app without agreeing, and change your choice later in settings.',
    acceptAll: 'Agree to all',
    declineAll: 'Do not agree',
    customize: 'Choose individually',
    settingsTitle: 'Privacy settings',
    settingsBody: 'Turn each item on or off.',
    close: 'Close',
    analyticsTitle: 'Usage analytics',
    analyticsBody: 'Counts how much each feature is used.',
    crashTitle: 'Error reports',
    crashBody: 'Sends information when the app stops, to help fix bugs.',
    adsTitle: 'Personalized ads',
    adsBody: 'When off, ads are not tailored to your interests.',
  );
  static const zhHans = ConsentStrings(
    menu: '隐私设置',
    promptTitle: '关于数据的使用',
    promptBody: '为改进应用，我们可能会收集使用情况和错误信息，不包含可识别个人的信息。不同意也可以使用全部功能，之后可在设置中更改。',
    acceptAll: '全部同意',
    declineAll: '不同意',
    customize: '逐项选择',
    settingsTitle: '隐私设置',
    settingsBody: '可逐项开启或关闭。',
    close: '关闭',
    analyticsTitle: '使用情况分析',
    analyticsBody: '统计各功能的使用情况。',
    crashTitle: '错误报告',
    crashBody: '应用异常停止时发送信息，用于修复问题。',
    adsTitle: '个性化广告',
    adsBody: '关闭后，广告不会根据兴趣定制。',
  );
  static const zhHant = ConsentStrings(
    menu: '隱私設定',
    promptTitle: '關於資料的使用',
    promptBody: '為改善應用程式，我們可能會蒐集使用情況與錯誤資訊，不含可識別個人的資訊。不同意也能使用全部功能，之後可在設定中變更。',
    acceptAll: '全部同意',
    declineAll: '不同意',
    customize: '逐項選擇',
    settingsTitle: '隱私設定',
    settingsBody: '可逐項開啟或關閉。',
    close: '關閉',
    analyticsTitle: '使用情況分析',
    analyticsBody: '統計各功能的使用情況。',
    crashTitle: '錯誤回報',
    crashBody: '應用程式異常停止時傳送資訊，用於修正問題。',
    adsTitle: '個人化廣告',
    adsBody: '關閉後，廣告不會依興趣量身打造。',
  );
  static const ko = ConsentStrings(
    menu: '개인정보 설정',
    promptTitle: '데이터 이용 안내',
    promptBody: '앱 개선을 위해 이용 현황과 오류 정보를 수집할 수 있습니다. 개인을 식별하는 정보는 포함하지 않습니다. 동의하지 않아도 모든 기능을 사용할 수 있으며, 나중에 설정에서 바꿀 수 있습니다.',
    acceptAll: '모두 동의',
    declineAll: '동의하지 않음',
    customize: '항목별로 선택',
    settingsTitle: '개인정보 설정',
    settingsBody: '항목별로 켜고 끌 수 있습니다.',
    close: '닫기',
    analyticsTitle: '이용 현황 분석',
    analyticsBody: '기능이 얼마나 쓰이는지 집계합니다.',
    crashTitle: '오류 전송',
    crashBody: '앱이 멈췄을 때 정보를 보내 문제 수정에 사용합니다.',
    adsTitle: '맞춤 광고',
    adsBody: '끄면 관심사에 맞추지 않은 광고가 표시됩니다.',
  );
}

/// 項目ごとに、オンとオフを選ぶ画面（設定から開く）。
Future<void> showConsentSettings(
  BuildContext context,
  ConsentController consent, {
  required ConsentStrings strings,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ConsentSettingsDialog(consent: consent, strings: strings),
    );

class _ConsentSettingsDialog extends StatelessWidget {
  const _ConsentSettingsDialog({required this.consent, required this.strings});

  final ConsentController consent;
  final ConsentStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: consent,
      builder: (context, _) => AlertDialog(
        // 文字を大きくした小さい画面でも、題名ごとスクロールして切れないようにする
        scrollable: true,
        title: Text(strings.settingsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.settingsBody),
            for (final c in consent.categories)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: consent.allows(c),
                onChanged: (v) => consent.set(c, v),
                title: Text(strings.titleOf(c)),
                subtitle: Text(strings.bodyOf(c)),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.close))],
      ),
    );
  }
}

/// 初回の案内。「すべて同意する」「同意しない」「項目ごとに選ぶ」を出し、選んだ結果を保存する。
///
/// 同意が不要（[ConsentController.needsPrompt] が false）なら、何も出さない。
/// 「同意しない」も、1つの回答として保存する（毎回は尋ねない）。
Future<void> showConsentPrompt(
  BuildContext context,
  ConsentController consent, {
  required ConsentStrings strings,
}) async {
  if (!consent.needsPrompt) return;
  final choice = await showDialog<_PromptChoice>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      scrollable: true,
      // 3 つの操作ボタンを縦に並べても収まるよう、画面端の余白を詰める
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Text(strings.promptTitle),
      content: Text(strings.promptBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, _PromptChoice.decline), child: Text(strings.declineAll)),
        TextButton(
            onPressed: () => Navigator.pop(context, _PromptChoice.customize), child: Text(strings.customize)),
        FilledButton(
            onPressed: () => Navigator.pop(context, _PromptChoice.accept), child: Text(strings.acceptAll)),
      ],
    ),
  );
  switch (choice) {
    case _PromptChoice.accept:
      await consent.setAll(true);
    case _PromptChoice.decline:
      await consent.setAll(false);
    case _PromptChoice.customize:
      // 項目ごとの画面を出す。閉じたら、触っていない項目は「同意しない」で確定する。
      if (!context.mounted) return;
      await showConsentSettings(context, consent, strings: strings);
      for (final c in consent.categories.where(consent.isUnanswered).toList()) {
        await consent.set(c, false);
      }
    case null:
      break;
  }
}

enum _PromptChoice { accept, decline, customize }
