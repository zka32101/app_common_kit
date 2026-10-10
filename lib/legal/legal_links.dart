import 'package:flutter/material.dart';

/// アプリが公開している法務文書・問い合わせ先へのリンク。**文面はキットに含まない**
/// （各アプリの実態に合わせ、専門家の確認を経た文書を、アプリ自身が公開する）。
///
/// URL は `https://` のみ受け付ける。空欄・不正な URL の項目は欄を出さない。
class LegalLinks {
  const LegalLinks({
    this.privacyPolicyUrl,
    this.termsUrl,
    this.commercialDisclosureUrl,
    this.contactUrl,
  });

  /// プライバシーポリシー。
  final String? privacyPolicyUrl;

  /// 利用規約。
  final String? termsUrl;

  /// 特定商取引法に基づく表記（有料のアプリ内課金がある場合）。
  final String? commercialDisclosureUrl;

  /// お問い合わせ先（フォームの URL）。
  final String? contactUrl;

  /// 安全な（https の）URL か。
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final u = Uri.tryParse(url);
    return u != null && u.scheme == 'https' && u.host.isNotEmpty;
  }

  /// 欄を出す項目（種類と URL）。順序は、プライバシー・規約・特商法・お問い合わせ。
  List<({LegalKind kind, Uri uri})> get entries => [
        for (final e in [
          (LegalKind.privacyPolicy, privacyPolicyUrl),
          (LegalKind.terms, termsUrl),
          (LegalKind.commercialDisclosure, commercialDisclosureUrl),
          (LegalKind.contact, contactUrl),
        ])
          if (isValidUrl(e.$2)) (kind: e.$1, uri: Uri.parse(e.$2!)),
      ];

  bool get isEmpty => entries.isEmpty;
}

enum LegalKind { privacyPolicy, terms, commercialDisclosure, contact }

/// 法務リンクの表示名。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き）。
class LegalStrings {
  const LegalStrings({
    required this.privacyPolicy,
    required this.terms,
    required this.commercialDisclosure,
    required this.contact,
  });

  final String privacyPolicy;
  final String terms;
  final String commercialDisclosure;
  final String contact;

  String of(LegalKind k) => switch (k) {
        LegalKind.privacyPolicy => privacyPolicy,
        LegalKind.terms => terms,
        LegalKind.commercialDisclosure => commercialDisclosure,
        LegalKind.contact => contact,
      };

  /// `KitStrings.languageCode`（`ja`・`en`・`zh`・`zh-Hant`・`ko`）に合わせて選ぶ。それ以外は日本語。
  static LegalStrings forCode(String code) => switch (code) {
        'en' => en,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        'ko' => ko,
        _ => ja,
      };

  static const ja = LegalStrings(
    privacyPolicy: 'プライバシーポリシー',
    terms: '利用規約',
    commercialDisclosure: '特定商取引法に基づく表記',
    contact: 'お問い合わせ',
  );
  static const en = LegalStrings(
    privacyPolicy: 'Privacy Policy',
    terms: 'Terms of Use',
    commercialDisclosure: 'Legal Notice (Specified Commercial Transactions Act)',
    contact: 'Contact',
  );
  static const zhHans = LegalStrings(
    privacyPolicy: '隐私政策',
    terms: '使用条款',
    commercialDisclosure: '特定商业交易法标示',
    contact: '联系我们',
  );
  static const zhHant = LegalStrings(
    privacyPolicy: '隱私權政策',
    terms: '使用條款',
    commercialDisclosure: '特定商業交易法標示',
    contact: '聯絡我們',
  );
  static const ko = LegalStrings(
    privacyPolicy: '개인정보 처리방침',
    terms: '이용약관',
    commercialDisclosure: '특정상거래법에 따른 표기',
    contact: '문의하기',
  );
}

/// 法務リンクの欄（設定画面などに並べる）。タップしたら [onOpen] を呼ぶ
/// （外部ブラウザで開く処理は、アプリが `url_launcher` などで実装して渡す）。
class LegalSection extends StatelessWidget {
  const LegalSection({super.key, required this.links, required this.strings, required this.onOpen});

  final LegalLinks links;
  final LegalStrings strings;
  final ValueChanged<Uri> onOpen;

  static const _icons = {
    LegalKind.privacyPolicy: Icons.privacy_tip_outlined,
    LegalKind.terms: Icons.description_outlined,
    LegalKind.commercialDisclosure: Icons.receipt_long_outlined,
    LegalKind.contact: Icons.mail_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in links.entries)
          ListTile(
            leading: Icon(_icons[e.kind]),
            title: Text(strings.of(e.kind)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => onOpen(e.uri),
          ),
      ],
    );
  }
}
