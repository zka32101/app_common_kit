import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entitlement/purchase_section.dart';
import '../hands_free/hands_free_settings.dart';
import '../legal/legal_links.dart';
import '../privacy/data_deletion.dart';
import '../theme/theme_mode_store.dart';
import '../widgets/feedback_form_page.dart';
import 'exam_date_tile.dart';
import 'kit_strings.dart';

/// 言語の選択肢（コードと、その言語での表示名）。例: `SettingsLanguage('en', 'English')`。
class SettingsLanguage {
  const SettingsLanguage(this.code, this.label);

  final String code;
  final String label;
}

/// 設定タブの完成品。全アプリで同じ並びの設定画面になる。
///
/// 項目はそれぞれ任意で、引数で出し分ける。
///
/// | 項目 | 出す条件 |
/// |---|---|
/// | 受験日 | [onExamDateChanged] を渡す |
/// | 購入（広告非表示・プレミアム） | [showPurchase]（既定 true）。`entitlementServiceProvider` の override が要る |
/// | 表示モード | [showTheme]（既定 true） |
/// | 言語 | [languages] が2つ以上で、[onLanguageChanged] を渡す |
/// | 片手・ながら学習 | [showHandsFree]（既定 true）。`handsFreeStoreProvider` の override が要る |
/// | ご意見・不具合報告 | [showFeedback]（既定 true） |
/// | 学習の引き継ぎ | [onTransfer] を渡す（画面はアプリ側が出す） |
/// | 法務リンク | [legal] と [onOpenLink] を渡す（文面は各アプリが公開する） |
/// | データを削除 | [dataDeletion] を渡す（確認と削除はキットが行う） |
/// | このアプリについて | 常に出す（[disclaimer] があれば表示する） |
///
/// アプリ固有の項目は [extraSections] に足す（[SettingsSection] を使うと見出しがそろう）。
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
///   appName: 'ITパスポート',
///   appVersion: '1.2.0',
///   examDate: examDate,
///   onExamDateChanged: saveExamDate,
///   languages: const [SettingsLanguage('ja', '日本語'), SettingsLanguage('en', 'English')],
///   languageCode: currentCode,
///   onLanguageChanged: changeLanguage,
///   disclaimer: '本アプリは試験団体とは関係のない非公式のアプリです。',
/// )));
/// ```
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.appName,
    this.appVersion = '',
    this.userId,
    this.strings,
    this.showTheme = true,
    this.languages = const [],
    this.languageCode,
    this.onLanguageChanged,
    this.showHandsFree = true,
    this.showPurchase = true,
    this.examDate,
    this.onExamDateChanged,
    this.showFeedback = true,
    this.onTransfer,
    this.legal,
    this.onOpenLink,
    this.dataDeletion,
    this.onDataDeleted,
    this.disclaimer,
    this.extraSections = const [],
  });

  /// アプリ名（フィードバックの送信元・「このアプリについて」に使う）。
  final String appName;
  final String appVersion;

  /// フィードバックに添える利用者ID（任意）。
  final String? userId;

  /// 文言。null なら最も近い `KitStringsScope`（無ければ日本語）。
  /// 画面は Navigator の上に積まれるため、Scope は `MaterialApp.builder` など Navigator より上に置くか、ここで渡す。
  final KitStrings? strings;

  final bool showTheme;

  /// 選べる言語。2つ以上あるときだけ「言語」の欄を出す。
  final List<SettingsLanguage> languages;

  /// いまの言語のコード。
  final String? languageCode;

  /// 言語を選んだときに呼ばれる。保存と、アプリの文言の切り替えはアプリ側が行う。
  final ValueChanged<String>? onLanguageChanged;

  final bool showHandsFree;
  final bool showPurchase;

  /// 受験日。未設定なら null。
  final DateTime? examDate;

  /// 渡すと「受験日」の欄を出す。選んだ日付、解除したとき（null）に呼ばれる。保存はアプリ側。
  final ValueChanged<DateTime?>? onExamDateChanged;

  final bool showFeedback;

  /// 渡すと「学習の引き継ぎ」の欄を出す。押したら、アプリ側が引き継ぎの画面を開く。
  final VoidCallback? onTransfer;

  /// 渡すと「プライバシーポリシー」「利用規約」などの欄を出す。URL を開く処理 [onOpenLink] も要る。
  final LegalLinks? legal;

  /// 法務リンクを開く処理（外部ブラウザ）。アプリが `url_launcher` などで実装する。
  final ValueChanged<Uri>? onOpenLink;

  /// 渡すと「データを削除」の欄を出す。確認 → 削除 → 結果の通知までをキットが行う。
  final DataDeletion? dataDeletion;

  /// 削除が済んだ（失敗を含む）ときに呼ばれる。初期画面へ戻す等はアプリ側で行う。
  final ValueChanged<DeletionResult>? onDataDeleted;

  /// 「このアプリについて」に出す免責の文面（試験団体と無関係であること、など）。
  final String? disclaimer;

  /// アプリ固有の項目。「このアプリについて」の前に並ぶ。
  final List<Widget> extraSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings ?? KitStrings.of(context);
    final sections = <Widget>[
      if (onExamDateChanged != null)
        ExamDateTile(date: examDate, onChanged: onExamDateChanged!),
      if (showPurchase) const PurchaseSection(),
      if (showTheme) _ThemeSection(strings: s),
      if (languages.length >= 2 && onLanguageChanged != null)
        _LanguageSection(
          strings: s,
          languages: languages,
          current: languageCode,
          onChanged: onLanguageChanged!,
        ),
      if (showHandsFree) _HandsFreeSection(strings: s),
      ...extraSections,
      if (showFeedback)
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: Text(s.feedbackTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => FeedbackFormPage(
              appName: appName,
              appVersion: appVersion,
              userId: userId,
              strings: s,
            ),
          )),
        ),
      if (onTransfer != null)
        ListTile(
          leading: const Icon(Icons.phonelink_setup),
          title: Text(s.settingsTransfer),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTransfer,
        ),
      if (legal != null && onOpenLink != null && !legal!.isEmpty)
        LegalSection(
          links: legal!,
          strings: LegalStrings.forCode(s.languageCode),
          onOpen: onOpenLink!,
        ),
      if (dataDeletion != null)
        Builder(builder: (context) {
          final d = DataDeletionStrings.forCode(s.languageCode);
          return ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(d.menu),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final r = await showDataDeletionFlow(context, dataDeletion!, strings: d);
              if (r != null) onDataDeleted?.call(r);
            },
          );
        }),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(s.settingsAbout),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAbout(context, s),
      ),
    ];

    // 中の部品（購入欄・受験日など）も同じ言語で出す。
    return KitStringsScope(
      strings: s,
      child: Scaffold(
        appBar: AppBar(title: Text(s.settingsTitle)),
        body: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (_, i) => sections[i],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, KitStrings s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appVersion.isNotEmpty) Text(s.aboutVersion(appVersion)),
              if (disclaimer != null) ...[
                const SizedBox(height: 12),
                Text(disclaimer!),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(s.close))],
      ),
    );
  }
}

/// 設定画面の項目。見出しと、その下の中身。[SettingsScreen.extraSections] に使う。
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      );
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.strings});

  final KitStrings strings;

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: strings.settingsTheme,
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(strings.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(strings.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(strings.themeDark)),
              ],
              selected: {mode},
              onSelectionChanged: (v) => setThemeMode(v.first),
            ),
          ),
        ],
      );
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.strings,
    required this.languages,
    required this.current,
    required this.onChanged,
  });

  final KitStrings strings;
  final List<SettingsLanguage> languages;
  final String? current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: strings.settingsLanguage,
        children: [
          for (final l in languages)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.label),
              selected: l.code == current,
              trailing: l.code == current ? const Icon(Icons.check) : null,
              onTap: () => onChanged(l.code),
            ),
        ],
      );
}

class _HandsFreeSection extends ConsumerWidget {
  const _HandsFreeSection({required this.strings});

  final KitStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(handsFreeProvider);
    final notifier = ref.read(handsFreeProvider.notifier);
    return SettingsSection(
      title: strings.settingsHandsFree,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.handsFreeEnable),
          value: settings.enabled,
          onChanged: notifier.setEnabled,
        ),
        if (settings.enabled) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeakQuestion),
            value: settings.speakQuestion,
            onChanged: notifier.setSpeakQuestion,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeakExplanation),
            value: settings.speakExplanation,
            onChanged: notifier.setSpeakExplanation,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeed),
            trailing: Text('${settings.speechRate.toStringAsFixed(1)}x'),
          ),
          Slider(
            // 読み上げソフトに「読み上げの速さ」と伝わるようにする（スライダー単体にはラベルが付かない）
            semanticFormatterCallback: (v) => '${strings.handsFreeSpeed} ${v.toStringAsFixed(1)}x',
            value: settings.speechRate,
            min: HandsFreeSettings.minSpeechRate,
            max: HandsFreeSettings.maxSpeechRate,
            divisions: 10,
            label: '${settings.speechRate.toStringAsFixed(1)}x',
            onChanged: notifier.setSpeechRate,
          ),
        ],
      ],
    );
  }
}
