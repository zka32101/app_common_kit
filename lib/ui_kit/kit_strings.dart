import 'kit_strings_ko.dart';
import 'kit_strings_zh_hans.dart';
import 'kit_strings_zh_hant.dart';
import 'package:flutter/widgets.dart';
import '../hands_free/nagara_strings.dart';

/// キット内蔵ウィジェットの既定文言（日本語・英語）。
///
/// 既定は日本語。端末の言語には自動で従わず、アプリが [KitStringsScope] で明示したときだけ切り替わる
/// （既存アプリの表示が勝手に変わらない）。個別の引数で文言を渡した場合は、そちらが優先される。
@immutable
class KitStrings {
  const KitStrings({
    required this.languageCode,
    required this.reviewEnjoyTitle,
    required this.updateRequiredTitle,
    required this.updateRequiredBody,
    required this.updateAvailableTitle,
    required this.updateAvailableBody,
    required this.updateNow,
    required this.updateLater,
    required this.reviewYes,
    required this.reviewNo,
    required this.reviewLater,
    required this.purchaseTitle,
    required this.purchasedPremium,
    required this.purchasedNoAds,
    required this.purchaseRestore,
    required this.purchaseSuccess,
    required this.purchaseCancelled,
    required this.purchaseBlocked,
    required this.purchaseFailed,
    required this.restoreDone,
    required this.restoreNone,
    required this.examDateTitle,
    required this.examDateUnset,
    required this.examDateClear,
    required this.minutesBadge,
    required this.premiumLocked,
    required this.settingsTitle,
    required this.settingsTheme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.settingsLanguage,
    this.nagara = NagaraStrings.ja,
    required this.settingsHandsFree,
    required this.handsFreeEnable,
    required this.handsFreeSpeakQuestion,
    required this.handsFreeSpeakExplanation,
    required this.handsFreeSpeed,
    required this.settingsTransfer,
    required this.settingsAbout,
    required this.aboutVersion,
    required this.errorMessage,
    required this.retry,
    required this.streakZero,
    required this.streakDays,
    required this.streakSemantics,
    required this.accuracy,
    required this.correctOfTotal,
    required this.passLineReached,
    required this.passLineNotYet,
    required this.passLine,
    required this.again,
    required this.close,
    required this.feedbackTitle,
    required this.feedbackType,
    required this.feedbackBug,
    required this.feedbackFeature,
    required this.feedbackOther,
    required this.feedbackSubject,
    required this.feedbackSubjectHint,
    required this.feedbackDetail,
    required this.feedbackDetailHint,
    required this.feedbackSubmit,
    required this.feedbackSent,
    required this.feedbackFailed,
    required this.feedbackTitleRequired,
    required this.feedbackDetailRequired,
    required this.feedbackTitleTooLong,
    required this.feedbackDetailTooLong,
    required this.correctLabel,
    required this.incorrectLabel,
    required this.sentenceSeparator,
    required this.explanationTitle,
    required this.readAloud,
    required this.sourceNote,
    required this.sourceNoteChecked,
    this.questionNo = _jaQuestionNo,
    this.questionNoOfTotal = _jaQuestionNoOfTotal,
    this.progressDefault = '進捗',
  });

  /// 言語コード（`ja` / `en`）。マスコットのセリフ選びなどに使う。
  final String languageCode;

  /// 問題カードの見出し（「第3問」）と、進捗リングの既定ラベル。
  /// 指定しない言語では日本語になる（英語は [en] で指定）。
  final String Function(int index) questionNo;
  final String Function(int index, int total) questionNoOfTotal;
  final String progressDefault;
  final String reviewEnjoyTitle;
  final String updateRequiredTitle;
  final String updateRequiredBody;
  final String updateAvailableTitle;
  final String updateAvailableBody;
  final String updateNow;
  final String updateLater;
  final String reviewYes;
  final String reviewNo;
  final String reviewLater;
  final String purchaseTitle;
  final String purchasedPremium;
  final String purchasedNoAds;
  final String purchaseRestore;
  final String purchaseSuccess;
  final String purchaseCancelled;
  final String purchaseBlocked;
  final String purchaseFailed;
  final String restoreDone;
  final String restoreNone;
  final String examDateTitle;
  final String examDateUnset;
  final String examDateClear;

  /// 体験・コンテンツカードの所要時間バッジ（「約n分」）。
  final String Function(int minutes) minutesBadge;

  /// プレミアム限定カードの鍵アイコンのアクセシビリティ用ラベル。
  final String premiumLocked;
  final String settingsTitle;
  final String settingsTheme;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String settingsLanguage;
  /// ながらセッションの文言（省略すると日本語。ko・zh も日本語のまま）。
  final NagaraStrings nagara;

  final String settingsHandsFree;
  final String handsFreeEnable;
  final String handsFreeSpeakQuestion;
  final String handsFreeSpeakExplanation;
  final String handsFreeSpeed;
  final String settingsTransfer;
  final String settingsAbout;
  final String Function(String version) aboutVersion;

  final String errorMessage;
  final String retry;
  final String streakZero;
  final String Function(int days) streakDays;
  final String Function(int days) streakSemantics;
  final String accuracy;
  final String Function(int correct, int total) correctOfTotal;
  final String passLineReached;
  final String passLineNotYet;
  final String Function(int percent) passLine;
  final String again;
  final String close;
  final String feedbackTitle;
  final String feedbackType;
  final String feedbackBug;
  final String feedbackFeature;
  final String feedbackOther;
  final String feedbackSubject;
  final String feedbackSubjectHint;
  final String feedbackDetail;
  final String feedbackDetailHint;
  final String feedbackSubmit;
  final String feedbackSent;
  final String feedbackFailed;

  final String feedbackTitleRequired;
  final String feedbackDetailRequired;
  final String Function(int max) feedbackTitleTooLong;
  final String Function(int max) feedbackDetailTooLong;
  final String correctLabel;
  final String incorrectLabel;
  final String sentenceSeparator;
  final String explanationTitle;
  final String readAloud;
  final String Function(String src) sourceNote;
  final String Function(String src, String checkedAt) sourceNoteChecked;

  /// 一部の文言だけ差し替えた複製を返す（ほかの言語の土台にも使える）。
  KitStrings copyWith({
    String? languageCode,
    String? reviewEnjoyTitle,
    String? updateRequiredTitle,
    String? updateRequiredBody,
    String? updateAvailableTitle,
    String? updateAvailableBody,
    String? updateNow,
    String? updateLater,
    String? reviewYes,
    String? reviewNo,
    String? reviewLater,
    String? purchaseTitle,
    String? purchasedPremium,
    String? purchasedNoAds,
    String? purchaseRestore,
    String? purchaseSuccess,
    String? purchaseCancelled,
    String? purchaseBlocked,
    String? purchaseFailed,
    String? restoreDone,
    String? restoreNone,
    String? examDateTitle,
    String? examDateUnset,
    String? examDateClear,
    String Function(int minutes)? minutesBadge,
    String? premiumLocked,
    String? settingsTitle,
    String? settingsTheme,
    String? themeSystem,
    String? themeLight,
    String? themeDark,
    String? settingsLanguage,
    NagaraStrings? nagara,
    String? settingsHandsFree,
    String? handsFreeEnable,
    String? handsFreeSpeakQuestion,
    String? handsFreeSpeakExplanation,
    String? handsFreeSpeed,
    String? settingsTransfer,
    String? settingsAbout,
    String Function(String version)? aboutVersion,
    String? errorMessage,
    String? retry,
    String? streakZero,
    String Function(int days)? streakDays,
    String Function(int days)? streakSemantics,
    String? accuracy,
    String Function(int correct, int total)? correctOfTotal,
    String? passLineReached,
    String? passLineNotYet,
    String Function(int percent)? passLine,
    String? again,
    String? close,
    String? feedbackTitle,
    String? feedbackType,
    String? feedbackBug,
    String? feedbackFeature,
    String? feedbackOther,
    String? feedbackSubject,
    String? feedbackSubjectHint,
    String? feedbackDetail,
    String? feedbackDetailHint,
    String? feedbackSubmit,
    String? feedbackSent,
    String? feedbackFailed,
    String? feedbackTitleRequired,
    String? feedbackDetailRequired,
    String Function(int max)? feedbackTitleTooLong,
    String Function(int max)? feedbackDetailTooLong,
    String? correctLabel,
    String? incorrectLabel,
    String? sentenceSeparator,
    String? explanationTitle,
    String? readAloud,
    String Function(String src)? sourceNote,
    String Function(String src, String checkedAt)? sourceNoteChecked,
    String Function(int index)? questionNo,
    String Function(int index, int total)? questionNoOfTotal,
    String? progressDefault,
  }) => KitStrings(
    languageCode: languageCode ?? this.languageCode,
    reviewEnjoyTitle: reviewEnjoyTitle ?? this.reviewEnjoyTitle,
    updateRequiredTitle: updateRequiredTitle ?? this.updateRequiredTitle,
    updateRequiredBody: updateRequiredBody ?? this.updateRequiredBody,
    updateAvailableTitle: updateAvailableTitle ?? this.updateAvailableTitle,
    updateAvailableBody: updateAvailableBody ?? this.updateAvailableBody,
    updateNow: updateNow ?? this.updateNow,
    updateLater: updateLater ?? this.updateLater,
    reviewYes: reviewYes ?? this.reviewYes,
    reviewNo: reviewNo ?? this.reviewNo,
    reviewLater: reviewLater ?? this.reviewLater,
    purchaseTitle: purchaseTitle ?? this.purchaseTitle,
    purchasedPremium: purchasedPremium ?? this.purchasedPremium,
    purchasedNoAds: purchasedNoAds ?? this.purchasedNoAds,
    purchaseRestore: purchaseRestore ?? this.purchaseRestore,
    purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    purchaseCancelled: purchaseCancelled ?? this.purchaseCancelled,
    purchaseBlocked: purchaseBlocked ?? this.purchaseBlocked,
    purchaseFailed: purchaseFailed ?? this.purchaseFailed,
    restoreDone: restoreDone ?? this.restoreDone,
    restoreNone: restoreNone ?? this.restoreNone,
    examDateTitle: examDateTitle ?? this.examDateTitle,
    examDateUnset: examDateUnset ?? this.examDateUnset,
    examDateClear: examDateClear ?? this.examDateClear,
    minutesBadge: minutesBadge ?? this.minutesBadge,
    premiumLocked: premiumLocked ?? this.premiumLocked,
    settingsTitle: settingsTitle ?? this.settingsTitle,
    settingsTheme: settingsTheme ?? this.settingsTheme,
    themeSystem: themeSystem ?? this.themeSystem,
    themeLight: themeLight ?? this.themeLight,
    themeDark: themeDark ?? this.themeDark,
    settingsLanguage: settingsLanguage ?? this.settingsLanguage,
    nagara: nagara ?? this.nagara,
    settingsHandsFree: settingsHandsFree ?? this.settingsHandsFree,
    handsFreeEnable: handsFreeEnable ?? this.handsFreeEnable,
    handsFreeSpeakQuestion:
        handsFreeSpeakQuestion ?? this.handsFreeSpeakQuestion,
    handsFreeSpeakExplanation:
        handsFreeSpeakExplanation ?? this.handsFreeSpeakExplanation,
    handsFreeSpeed: handsFreeSpeed ?? this.handsFreeSpeed,
    settingsTransfer: settingsTransfer ?? this.settingsTransfer,
    settingsAbout: settingsAbout ?? this.settingsAbout,
    aboutVersion: aboutVersion ?? this.aboutVersion,
    errorMessage: errorMessage ?? this.errorMessage,
    retry: retry ?? this.retry,
    streakZero: streakZero ?? this.streakZero,
    streakDays: streakDays ?? this.streakDays,
    streakSemantics: streakSemantics ?? this.streakSemantics,
    accuracy: accuracy ?? this.accuracy,
    correctOfTotal: correctOfTotal ?? this.correctOfTotal,
    passLineReached: passLineReached ?? this.passLineReached,
    passLineNotYet: passLineNotYet ?? this.passLineNotYet,
    passLine: passLine ?? this.passLine,
    again: again ?? this.again,
    close: close ?? this.close,
    feedbackTitle: feedbackTitle ?? this.feedbackTitle,
    feedbackType: feedbackType ?? this.feedbackType,
    feedbackBug: feedbackBug ?? this.feedbackBug,
    feedbackFeature: feedbackFeature ?? this.feedbackFeature,
    feedbackOther: feedbackOther ?? this.feedbackOther,
    feedbackSubject: feedbackSubject ?? this.feedbackSubject,
    feedbackSubjectHint: feedbackSubjectHint ?? this.feedbackSubjectHint,
    feedbackDetail: feedbackDetail ?? this.feedbackDetail,
    feedbackDetailHint: feedbackDetailHint ?? this.feedbackDetailHint,
    feedbackSubmit: feedbackSubmit ?? this.feedbackSubmit,
    feedbackSent: feedbackSent ?? this.feedbackSent,
    feedbackFailed: feedbackFailed ?? this.feedbackFailed,
    feedbackTitleRequired: feedbackTitleRequired ?? this.feedbackTitleRequired,
    feedbackDetailRequired:
        feedbackDetailRequired ?? this.feedbackDetailRequired,
    feedbackTitleTooLong: feedbackTitleTooLong ?? this.feedbackTitleTooLong,
    feedbackDetailTooLong: feedbackDetailTooLong ?? this.feedbackDetailTooLong,
    correctLabel: correctLabel ?? this.correctLabel,
    incorrectLabel: incorrectLabel ?? this.incorrectLabel,
    sentenceSeparator: sentenceSeparator ?? this.sentenceSeparator,
    explanationTitle: explanationTitle ?? this.explanationTitle,
    readAloud: readAloud ?? this.readAloud,
    sourceNote: sourceNote ?? this.sourceNote,
    sourceNoteChecked: sourceNoteChecked ?? this.sourceNoteChecked,
    questionNo: questionNo ?? this.questionNo,
    questionNoOfTotal: questionNoOfTotal ?? this.questionNoOfTotal,
    progressDefault: progressDefault ?? this.progressDefault,
  );

  static const ja = KitStrings(
    languageCode: 'ja',
    reviewEnjoyTitle: 'アプリを楽しんでいますか？',
    updateRequiredTitle: 'アップデートが必要です',
    updateRequiredBody: 'このバージョンはご利用いただけません。最新版にアップデートしてください。',
    updateAvailableTitle: '新しいバージョンがあります',
    updateAvailableBody: '最新版にアップデートできます。',
    updateNow: 'アップデート',
    updateLater: 'あとで',
    reviewYes: 'はい',
    reviewNo: 'いいえ',
    reviewLater: 'あとで',
    purchaseTitle: '購入',
    purchasedPremium: 'プレミアムを購入済みです',
    purchasedNoAds: '広告非表示を購入済みです',
    purchaseRestore: '購入を復元',
    purchaseSuccess: '購入しました。',
    purchaseCancelled: '購入をキャンセルしました。',
    purchaseBlocked: '購入できませんでした。',
    purchaseFailed: '購入に失敗しました。',
    restoreDone: '購入を復元しました。',
    restoreNone: '復元できる購入がありませんでした。',
    examDateTitle: '受験日',
    examDateUnset: '未設定。入力すると直前の復習モードが使えます。',
    examDateClear: '受験日を解除',
    minutesBadge: _jaMinutesBadge,
    premiumLocked: 'プレミアム限定',
    settingsTitle: '設定',
    settingsTheme: '表示モード',
    themeSystem: '端末に合わせる',
    themeLight: 'ライト',
    themeDark: 'ダーク',
    settingsLanguage: '言語',
    settingsHandsFree: '片手・ながら学習',
    handsFreeEnable: '片手モードを使う',
    handsFreeSpeakQuestion: '問題を読み上げる',
    handsFreeSpeakExplanation: '解説を読み上げる',
    handsFreeSpeed: '読み上げの速さ',
    settingsTransfer: '学習の引き継ぎ（機種変更）',
    settingsAbout: 'このアプリについて',
    aboutVersion: _jaAboutVersion,
    errorMessage: '読み込めませんでした。通信を確認して、もう一度お試しください。',
    retry: 'もう一度試す',
    streakZero: '今日から始めよう',
    streakDays: _jaStreakDays,
    streakSemantics: _jaStreakSemantics,
    accuracy: '正答率',
    correctOfTotal: _jaCorrectOfTotal,
    passLineReached: '合格ライン到達',
    passLineNotYet: 'あと少し。弱点を復習しよう',
    passLine: _jaPassLine,
    again: 'もう一度',
    close: '閉じる',
    feedbackTitle: 'ご意見・不具合報告',
    feedbackType: '種別',
    feedbackBug: '不具合報告',
    feedbackFeature: '改善要望',
    feedbackOther: 'その他',
    feedbackSubject: 'タイトル',
    feedbackSubjectHint: '例：〇〇画面でボタンが反応しない',
    feedbackDetail: '詳細',
    feedbackDetailHint: 'できるだけ詳しく状況を教えてください',
    feedbackSubmit: '送信する',
    feedbackSent: '送信しました。ありがとうございます！',
    feedbackFailed: '送信に失敗しました。時間をおいて再度お試しください。',
    feedbackTitleRequired: 'タイトルを入力してください',
    feedbackDetailRequired: '詳細を入力してください',
    feedbackTitleTooLong: _jaTitleTooLong,
    feedbackDetailTooLong: _jaDetailTooLong,
    correctLabel: '正解',
    incorrectLabel: '不正解',
    sentenceSeparator: '。',
    explanationTitle: '解説',
    readAloud: '読み上げ',
    sourceNote: _jaSourceNote,
    sourceNoteChecked: _jaSourceNoteChecked,
);

  static const en = KitStrings(
    languageCode: 'en',
    reviewEnjoyTitle: 'Are you enjoying the app?',
    updateRequiredTitle: 'Update required',
    updateRequiredBody:
        'This version is no longer supported. Please update to the latest version.',
    updateAvailableTitle: 'A new version is available',
    updateAvailableBody: 'You can update to the latest version.',
    updateNow: 'Update',
    updateLater: 'Later',
    reviewYes: 'Yes',
    reviewNo: 'Not really',
    reviewLater: 'Later',
    purchaseTitle: 'Purchases',
    purchasedPremium: 'You own Premium',
    purchasedNoAds: 'You own Ad-free',
    purchaseRestore: 'Restore purchases',
    purchaseSuccess: 'Purchase complete.',
    purchaseCancelled: 'Purchase cancelled.',
    purchaseBlocked: 'Could not purchase.',
    purchaseFailed: 'Purchase failed.',
    restoreDone: 'Purchases restored.',
    restoreNone: 'No purchases to restore.',
    examDateTitle: 'Exam date',
    examDateUnset: 'Not set. Set it to use the last-minute review mode.',
    examDateClear: 'Clear exam date',
    minutesBadge: _enMinutesBadge,
    premiumLocked: 'Premium only',
    settingsTitle: 'Settings',
    settingsTheme: 'Appearance',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    settingsLanguage: 'Language',
    nagara: NagaraStrings.en,
    settingsHandsFree: 'One-handed study',
    handsFreeEnable: 'Use one-handed mode',
    handsFreeSpeakQuestion: 'Read questions aloud',
    handsFreeSpeakExplanation: 'Read explanations aloud',
    handsFreeSpeed: 'Reading speed',
    settingsTransfer: 'Transfer your progress',
    settingsAbout: 'About this app',
    aboutVersion: _enAboutVersion,
    errorMessage: "Couldn't load. Please check your connection and try again.",
    retry: 'Try again',
    streakZero: 'Start today',
    streakDays: _enStreakDays,
    streakSemantics: _enStreakSemantics,
    accuracy: 'Accuracy',
    correctOfTotal: _enCorrectOfTotal,
    passLineReached: 'Passing line reached',
    passLineNotYet: 'Almost there. Review your weak spots',
    passLine: _enPassLine,
    again: 'Retry',
    close: 'Close',
    feedbackTitle: 'Feedback & bug reports',
    feedbackType: 'Type',
    feedbackBug: 'Bug report',
    feedbackFeature: 'Feature request',
    feedbackOther: 'Other',
    feedbackSubject: 'Title',
    feedbackSubjectHint: 'e.g. The button on the X screen does not respond',
    feedbackDetail: 'Details',
    feedbackDetailHint:
        'Please describe the situation in as much detail as you can',
    feedbackSubmit: 'Send',
    feedbackSent: 'Sent. Thank you!',
    feedbackFailed: 'Could not send. Please try again later.',
    feedbackTitleRequired: 'Please enter a title',
    feedbackDetailRequired: 'Please enter the details',
    feedbackTitleTooLong: _enTitleTooLong,
    feedbackDetailTooLong: _enDetailTooLong,
    correctLabel: 'Correct',
    incorrectLabel: 'Incorrect',
    sentenceSeparator: '. ',
    explanationTitle: 'Explanation',
    readAloud: 'Read aloud',
    sourceNote: _enSourceNote,
    sourceNoteChecked: _enSourceNoteChecked,
    questionNo: _enQuestionNo,
    questionNoOfTotal: _enQuestionNoOfTotal,
    progressDefault: 'Progress',
);

  /// 言語から選ぶ。内蔵は ja・en・簡体字(zh)・繁体字(zh-Hant、`zh_TW`/`zh_HK`/`zh_MO` も)・ko。
  /// アプリが用意した言語は [supported]（言語コード → 文言）で渡す（内蔵より優先）。
  /// どちらにも無い言語は日本語。
  ///
  /// ```dart
  /// KitStrings.forLocale(locale);                         // 内蔵の言語
  /// KitStrings.forLocale(locale, supported: {'vi': vi});  // ベトナム語などを足す
  /// ```
  static KitStrings forLocale(
    Locale locale, {
    Map<String, KitStrings> supported = const {},
  }) {
    final custom = supported[locale.languageCode];
    if (custom != null) return custom;
    switch (locale.languageCode) {
      case 'en':
        return en;
      case 'ko':
        return ko;
      case 'zh':
        return _isTraditionalChinese(locale) ? zhHant : zhHans;
      default:
        return ja;
    }
  }

  /// 繁体字か。`zh-Hant` か、台湾・香港・マカオ（スクリプト指定なし）なら繁体字。
  static bool _isTraditionalChinese(Locale l) =>
      l.scriptCode == 'Hant' ||
      (l.scriptCode == null &&
          const {'TW', 'HK', 'MO'}.contains(l.countryCode));

  /// 簡体字中国語（`zh`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHans = kitStringsZhHans;

  /// 繁体字中国語（`zh-Hant`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const zhHant = kitStringsZhHant;

  /// 韓国語（`ko`）。機械翻訳の下書き。公開前に母語話者の確認が要る。
  static const ko = kitStringsKo;

  /// 最も近い [KitStringsScope] の文言。無ければ日本語。
  static KitStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.strings ??
      ja;
}

String _jaStreakDays(int d) => '$d日連続';
String _jaStreakSemantics(int d) => '連続学習 $d日';
String _jaCorrectOfTotal(int c, int t) => '$c / $t 問正解';
String _jaPassLine(int p) => '合格ライン $p%';
String _jaMinutesBadge(int m) => '約$m分';
String _enStreakDays(int d) => '$d-day streak';
String _enStreakSemantics(int d) => 'Study streak $d days';
String _enCorrectOfTotal(int c, int t) => '$c of $t correct';
String _enPassLine(int p) => 'Passing line $p%';
String _enMinutesBadge(int m) => 'About $m min';

String _jaTitleTooLong(int m) => 'タイトルは$m文字以内で入力してください';
String _enTitleTooLong(int m) => 'Title must be $m characters or fewer';
String _jaDetailTooLong(int m) => '詳細は$m文字以内で入力してください';
String _enDetailTooLong(int m) => 'Details must be $m characters or fewer';

String _jaSourceNote(String s) => '出典: $s';
String _enSourceNote(String s) => 'Source: $s';
String _jaSourceNoteChecked(String s, String d) => '出典: $s（$d 確認）';
String _enSourceNoteChecked(String s, String d) => 'Source: $s (checked $d)';

String _jaQuestionNo(int i) => '第$i問';
String _enQuestionNo(int i) => 'Question $i';
String _jaQuestionNoOfTotal(int i, int total) => '第$i問 / $total問';
String _enQuestionNoOfTotal(int i, int total) => 'Question $i of $total';

String _jaAboutVersion(String v) => 'バージョン $v';
String _enAboutVersion(String v) => 'Version $v';

/// 配下のキットのウィジェットが使う文言を切り替える。
///
/// ```dart
/// KitStringsScope(strings: KitStrings.forLocale(locale), child: ...)
/// ```
///
/// ja/en 以外の言語を足すときは、文言の3つの束を渡す。渡さなかった束は、
/// [KitStrings.languageCode] が `en` なら英語、それ以外は日本語になる。
///
/// ```dart
/// KitStringsScope(
///   strings: zh,          // KitStrings（画面の文言）
///   child: ...,
/// )
/// ```
class KitStringsScope extends InheritedWidget {
  const KitStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final KitStrings strings;

  @override
  bool updateShouldNotify(KitStringsScope old) =>
      strings != old.strings;
}
