import 'package:flutter/widgets.dart';

import '../mascot/mascot_lines.dart';
import '../mascot/mascot_models.dart';
import 'lab_strings.dart';

/// キット内蔵ウィジェットの既定文言（日本語・英語）。
///
/// 既定は日本語。端末の言語には自動で従わず、アプリが [KitStringsScope] で明示したときだけ切り替わる
/// （既存アプリの表示が勝手に変わらない）。個別の引数で文言を渡した場合は、そちらが優先される。
@immutable
class KitStrings {
  const KitStrings({
    required this.languageCode,
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
    required this.settingsTitle,
    required this.settingsTheme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.settingsLanguage,
    required this.settingsHandsFree,
    required this.handsFreeEnable,
    required this.handsFreeSpeakQuestion,
    required this.handsFreeSpeakExplanation,
    required this.handsFreeSpeed,
    required this.settingsTransfer,
    required this.settingsAbout,
    required this.aboutVersion,
    required this.coinTotal,
    required this.coinBreakdownTitle,
    required this.coinEventLabels,
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
    required this.passAskBody,
    required this.passNotYet,
    required this.passNotPassed,
    required this.passPassed,
    required this.passEncourageTitle,
    required this.passEncourageBody,
    required this.passCongrats,
    required this.passPrivacy,
    required this.passShare,
    required this.wardrobeTitle,
    required this.wardrobeNote,
    required this.wardrobeInsufficient,
    required this.wardrobeAlreadyOwned,
    required this.wardrobeUnknown,
    required this.wardrobeCannotWear,
    required this.wardrobeWear,
    required this.wardrobeWearing,
    required this.wardrobeCanWear,
    required this.lockedNotPassed,
    required this.lockedNoExamDate,
    required this.lockedNotReady,
    required this.oshiMenuTooltip,
    required this.oshiChoose,
    required this.oshiPassReport,
    required this.oshiDisplayNormal,
    required this.oshiDisplaySmall,
    required this.oshiDisplayHidden,
    required this.oshiName,
    required this.oshiHiddenNote,
    required this.oshiYours,
    required this.oshiTapHint,
    required this.coinBalance,
    required this.wardrobePurchased,
    required this.wardrobePrice,
    required this.lockedNotPurchased,
    required this.passAskTitle,
    required this.passCoin,
    required this.passOutfit,
    required this.characterNames,
    required this.characterRoles,
    required this.feedbackTitleRequired,
    required this.feedbackDetailRequired,
    required this.feedbackTitleTooLong,
    required this.feedbackDetailTooLong,
    required this.correctLabel,
    required this.incorrectLabel,
    required this.sentenceSeparator,
    required this.explanationTitle,
    required this.tabLabels,
    required this.readAloud,
    required this.mockRecordTitle,
    required this.mockRecordNote,
    required this.mockRecordMessage,
    required this.sourceNote,
    required this.sourceNoteChecked,
    required this.mockRecordCert,
    required this.shareCardBrand,
    required this.shareCardPassed,
    required this.shareDate,
  });

  /// 言語コード（`ja` / `en`）。マスコットのセリフ選びなどに使う。
  final String languageCode;
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
  final String settingsTitle;
  final String settingsTheme;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String settingsLanguage;
  final String settingsHandsFree;
  final String handsFreeEnable;
  final String handsFreeSpeakQuestion;
  final String handsFreeSpeakExplanation;
  final String handsFreeSpeed;
  final String settingsTransfer;
  final String settingsAbout;
  final String Function(String version) aboutVersion;
  final String coinTotal;
  final String coinBreakdownTitle;

  /// `CoinEventType.name` → 表示名。
  final Map<String, String> coinEventLabels;
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
  final String passAskBody;
  final String passNotYet;
  final String passNotPassed;
  final String passPassed;
  final String passEncourageTitle;
  final String passEncourageBody;
  final String passCongrats;
  final String passPrivacy;
  final String passShare;
  final String wardrobeTitle;
  final String wardrobeNote;
  final String wardrobeInsufficient;
  final String wardrobeAlreadyOwned;
  final String wardrobeUnknown;
  final String wardrobeCannotWear;
  final String wardrobeWear;
  final String wardrobeWearing;
  final String wardrobeCanWear;
  final String lockedNotPassed;
  final String lockedNoExamDate;
  final String lockedNotReady;
  final String oshiMenuTooltip;
  final String oshiChoose;
  final String oshiPassReport;
  final String oshiDisplayNormal;
  final String oshiDisplaySmall;
  final String oshiDisplayHidden;
  final String oshiName;
  final String oshiHiddenNote;
  final String oshiYours;
  final String oshiTapHint;
  final String Function(int balance) coinBalance;
  final String Function(String name) wardrobePurchased;
  final String Function(int price) wardrobePrice;
  final String Function(int price) lockedNotPurchased;
  final String Function(String cert) passAskTitle;
  final String Function(int amount) passCoin;
  final String Function(String name) passOutfit;
  /// `CharacterPack.id` → 表示名。無い id はパックの name を使う。
  final Map<String, String> characterNames;

  /// `CharacterPack.id` → 役割の説明。
  final Map<String, String> characterRoles;
  final String feedbackTitleRequired;
  final String feedbackDetailRequired;
  final String Function(int max) feedbackTitleTooLong;
  final String Function(int max) feedbackDetailTooLong;
  final String correctLabel;
  final String incorrectLabel;
  final String sentenceSeparator;
  final String explanationTitle;
  final List<String> tabLabels;
  final String readAloud;
  final String mockRecordTitle;
  final String mockRecordNote;
  final String mockRecordMessage;
  final String Function(String src) sourceNote;
  final String Function(String src, String checkedAt) sourceNoteChecked;
  final String Function(String cert) mockRecordCert;
  final String shareCardBrand;
  final String shareCardPassed;
  final String Function(DateTime date) shareDate;

  /// 一部の文言だけ差し替えた複製を返す（ほかの言語の土台にも使える）。
  KitStrings copyWith({
    String? languageCode,
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
    String? settingsTitle,
    String? settingsTheme,
    String? themeSystem,
    String? themeLight,
    String? themeDark,
    String? settingsLanguage,
    String? settingsHandsFree,
    String? handsFreeEnable,
    String? handsFreeSpeakQuestion,
    String? handsFreeSpeakExplanation,
    String? handsFreeSpeed,
    String? settingsTransfer,
    String? settingsAbout,
    String Function(String version)? aboutVersion,
    String? coinTotal,
    String? coinBreakdownTitle,
    Map<String, String>? coinEventLabels,
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
    String? passAskBody,
    String? passNotYet,
    String? passNotPassed,
    String? passPassed,
    String? passEncourageTitle,
    String? passEncourageBody,
    String? passCongrats,
    String? passPrivacy,
    String? passShare,
    String? wardrobeTitle,
    String? wardrobeNote,
    String? wardrobeInsufficient,
    String? wardrobeAlreadyOwned,
    String? wardrobeUnknown,
    String? wardrobeCannotWear,
    String? wardrobeWear,
    String? wardrobeWearing,
    String? wardrobeCanWear,
    String? lockedNotPassed,
    String? lockedNoExamDate,
    String? lockedNotReady,
    String? oshiMenuTooltip,
    String? oshiChoose,
    String? oshiPassReport,
    String? oshiDisplayNormal,
    String? oshiDisplaySmall,
    String? oshiDisplayHidden,
    String? oshiName,
    String? oshiHiddenNote,
    String? oshiYours,
    String? oshiTapHint,
    String Function(int balance)? coinBalance,
    String Function(String name)? wardrobePurchased,
    String Function(int price)? wardrobePrice,
    String Function(int price)? lockedNotPurchased,
    String Function(String cert)? passAskTitle,
    String Function(int amount)? passCoin,
    String Function(String name)? passOutfit,
    Map<String, String>? characterNames,
    Map<String, String>? characterRoles,
    String? feedbackTitleRequired,
    String? feedbackDetailRequired,
    String Function(int max)? feedbackTitleTooLong,
    String Function(int max)? feedbackDetailTooLong,
    String? correctLabel,
    String? incorrectLabel,
    String? sentenceSeparator,
    String? explanationTitle,
    List<String>? tabLabels,
    String? readAloud,
    String? mockRecordTitle,
    String? mockRecordNote,
    String? mockRecordMessage,
    String Function(String src)? sourceNote,
    String Function(String src, String checkedAt)? sourceNoteChecked,
    String Function(String cert)? mockRecordCert,
    String? shareCardBrand,
    String? shareCardPassed,
    String Function(DateTime date)? shareDate,
  }) =>
      KitStrings(
      languageCode: languageCode ?? this.languageCode,
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
      settingsTitle: settingsTitle ?? this.settingsTitle,
      settingsTheme: settingsTheme ?? this.settingsTheme,
      themeSystem: themeSystem ?? this.themeSystem,
      themeLight: themeLight ?? this.themeLight,
      themeDark: themeDark ?? this.themeDark,
      settingsLanguage: settingsLanguage ?? this.settingsLanguage,
      settingsHandsFree: settingsHandsFree ?? this.settingsHandsFree,
      handsFreeEnable: handsFreeEnable ?? this.handsFreeEnable,
      handsFreeSpeakQuestion: handsFreeSpeakQuestion ?? this.handsFreeSpeakQuestion,
      handsFreeSpeakExplanation: handsFreeSpeakExplanation ?? this.handsFreeSpeakExplanation,
      handsFreeSpeed: handsFreeSpeed ?? this.handsFreeSpeed,
      settingsTransfer: settingsTransfer ?? this.settingsTransfer,
      settingsAbout: settingsAbout ?? this.settingsAbout,
      aboutVersion: aboutVersion ?? this.aboutVersion,
      coinTotal: coinTotal ?? this.coinTotal,
      coinBreakdownTitle: coinBreakdownTitle ?? this.coinBreakdownTitle,
      coinEventLabels: coinEventLabels ?? this.coinEventLabels,
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
      passAskBody: passAskBody ?? this.passAskBody,
      passNotYet: passNotYet ?? this.passNotYet,
      passNotPassed: passNotPassed ?? this.passNotPassed,
      passPassed: passPassed ?? this.passPassed,
      passEncourageTitle: passEncourageTitle ?? this.passEncourageTitle,
      passEncourageBody: passEncourageBody ?? this.passEncourageBody,
      passCongrats: passCongrats ?? this.passCongrats,
      passPrivacy: passPrivacy ?? this.passPrivacy,
      passShare: passShare ?? this.passShare,
      wardrobeTitle: wardrobeTitle ?? this.wardrobeTitle,
      wardrobeNote: wardrobeNote ?? this.wardrobeNote,
      wardrobeInsufficient: wardrobeInsufficient ?? this.wardrobeInsufficient,
      wardrobeAlreadyOwned: wardrobeAlreadyOwned ?? this.wardrobeAlreadyOwned,
      wardrobeUnknown: wardrobeUnknown ?? this.wardrobeUnknown,
      wardrobeCannotWear: wardrobeCannotWear ?? this.wardrobeCannotWear,
      wardrobeWear: wardrobeWear ?? this.wardrobeWear,
      wardrobeWearing: wardrobeWearing ?? this.wardrobeWearing,
      wardrobeCanWear: wardrobeCanWear ?? this.wardrobeCanWear,
      lockedNotPassed: lockedNotPassed ?? this.lockedNotPassed,
      lockedNoExamDate: lockedNoExamDate ?? this.lockedNoExamDate,
      lockedNotReady: lockedNotReady ?? this.lockedNotReady,
      oshiMenuTooltip: oshiMenuTooltip ?? this.oshiMenuTooltip,
      oshiChoose: oshiChoose ?? this.oshiChoose,
      oshiPassReport: oshiPassReport ?? this.oshiPassReport,
      oshiDisplayNormal: oshiDisplayNormal ?? this.oshiDisplayNormal,
      oshiDisplaySmall: oshiDisplaySmall ?? this.oshiDisplaySmall,
      oshiDisplayHidden: oshiDisplayHidden ?? this.oshiDisplayHidden,
      oshiName: oshiName ?? this.oshiName,
      oshiHiddenNote: oshiHiddenNote ?? this.oshiHiddenNote,
      oshiYours: oshiYours ?? this.oshiYours,
      oshiTapHint: oshiTapHint ?? this.oshiTapHint,
      coinBalance: coinBalance ?? this.coinBalance,
      wardrobePurchased: wardrobePurchased ?? this.wardrobePurchased,
      wardrobePrice: wardrobePrice ?? this.wardrobePrice,
      lockedNotPurchased: lockedNotPurchased ?? this.lockedNotPurchased,
      passAskTitle: passAskTitle ?? this.passAskTitle,
      passCoin: passCoin ?? this.passCoin,
      passOutfit: passOutfit ?? this.passOutfit,
      characterNames: characterNames ?? this.characterNames,
      characterRoles: characterRoles ?? this.characterRoles,
      feedbackTitleRequired: feedbackTitleRequired ?? this.feedbackTitleRequired,
      feedbackDetailRequired: feedbackDetailRequired ?? this.feedbackDetailRequired,
      feedbackTitleTooLong: feedbackTitleTooLong ?? this.feedbackTitleTooLong,
      feedbackDetailTooLong: feedbackDetailTooLong ?? this.feedbackDetailTooLong,
      correctLabel: correctLabel ?? this.correctLabel,
      incorrectLabel: incorrectLabel ?? this.incorrectLabel,
      sentenceSeparator: sentenceSeparator ?? this.sentenceSeparator,
      explanationTitle: explanationTitle ?? this.explanationTitle,
      tabLabels: tabLabels ?? this.tabLabels,
      readAloud: readAloud ?? this.readAloud,
      mockRecordTitle: mockRecordTitle ?? this.mockRecordTitle,
      mockRecordNote: mockRecordNote ?? this.mockRecordNote,
      mockRecordMessage: mockRecordMessage ?? this.mockRecordMessage,
      sourceNote: sourceNote ?? this.sourceNote,
      sourceNoteChecked: sourceNoteChecked ?? this.sourceNoteChecked,
      mockRecordCert: mockRecordCert ?? this.mockRecordCert,
      shareCardBrand: shareCardBrand ?? this.shareCardBrand,
      shareCardPassed: shareCardPassed ?? this.shareCardPassed,
      shareDate: shareDate ?? this.shareDate,
      );

  static const ja = KitStrings(
    languageCode: 'ja',
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
    coinTotal: '合計',
    coinBreakdownTitle: '今回貯まった学習コイン',
    coinEventLabels: {
      'newQuestion': '新しい問題',
      'coverageStep': '網羅率アップ',
      'accuracyMilestone': '正答率の達成',
      'accuracyBest': '自己ベスト更新',
      'reviewCorrected': '復習で克服',
      'dailyConsult': '今日の相談',
      'mockDone': '模擬試験の実施',
      'mockPass': '模擬試験で合格点',
      'mockBest': '模擬試験の自己ベスト',
      'streak': '連続学習',
      'passReport': '合格報告',
    },
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
    passAskBody: 'お知らせいただいた内容は、この端末の中だけで使います。',
    passNotYet: 'まだ・結果待ち',
    passNotPassed: '今回は合格できなかった',
    passPassed: '合格しました',
    passEncourageTitle: 'おつかれさまでした',
    passEncourageBody: '弱点を復習して、また挑戦しましょう。コインや衣装はそのままです。',
    passCongrats: '合格おめでとうございます',
    passPrivacy: '共有するカードに、名前などの個人情報は入りません。',
    passShare: '共有する',
    wardrobeTitle: '着替え・ショップ',
    wardrobeNote: 'コインは学習で貯まります。衣装は見た目だけで、学習の内容には影響しません。',
    wardrobeInsufficient: 'コインが足りません。学習すると貯まります',
    wardrobeAlreadyOwned: 'すでに持っています',
    wardrobeUnknown: '購入できません',
    wardrobeCannotWear: 'この衣装は今は着られません',
    wardrobeWear: '着る',
    wardrobeWearing: '着ています',
    wardrobeCanWear: '着られます',
    lockedNotPassed: '合格したときに解放されます',
    lockedNoExamDate: '試験日を設定すると着られます',
    lockedNotReady: '準備完了の目標を達成すると解放されます',
    oshiMenuTooltip: '推しのメニュー',
    oshiChoose: '推しを選ぶ',
    oshiPassReport: '試験の結果を報告',
    oshiDisplayNormal: '通常',
    oshiDisplaySmall: '小さく表示',
    oshiDisplayHidden: '表示しない',
    oshiName: '推し',
    oshiHiddenNote: '推しは非表示です',
    oshiYours: 'あなたの推し',
    oshiTapHint: '推しをタップすると、ひとこと話します',
    coinBalance: _jaCoinBalance,
    wardrobePurchased: _jaWardrobePurchased,
    wardrobePrice: _jaWardrobePrice,
    lockedNotPurchased: _jaLockedNotPurchased,
    passAskTitle: _jaPassAskTitle,
    passCoin: _jaPassCoin,
    passOutfit: _jaPassOutfit,
    characterNames: {},
    characterRoles: {
      'standard': 'フラスコの助手',
      'kai': '頼れる先輩',
      'mio': '明るい後輩',
      'moka': 'ゆるい相棒（犬）',
      'mike': 'ていねいな解説役（猫）',
    },
    feedbackTitleRequired: 'タイトルを入力してください',
    feedbackDetailRequired: '詳細を入力してください',
    feedbackTitleTooLong: _jaTitleTooLong,
    feedbackDetailTooLong: _jaDetailTooLong,
    correctLabel: '正解',
    incorrectLabel: '不正解',
    sentenceSeparator: '。',
    explanationTitle: '解説',
    tabLabels: ['ホーム', '学ぶ', '模擬', '記録', '設定'],
    readAloud: '読み上げ',
    mockRecordTitle: '学習の記録カード',
    mockRecordNote: '模擬試験の記録です。本番の合格ではありません。名前などの個人情報は入りません。',
    mockRecordMessage: '合格点を超えました！',
    sourceNote: _jaSourceNote,
    sourceNoteChecked: _jaSourceNoteChecked,
    mockRecordCert: _jaMockRecordCert,
    shareCardBrand: 'うかラボ',
    shareCardPassed: '合格しました！',
    shareDate: _jaShareDate,
  );

  static const en = KitStrings(
    languageCode: 'en',
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
    settingsTitle: 'Settings',
    settingsTheme: 'Appearance',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    settingsLanguage: 'Language',
    settingsHandsFree: 'One-handed study',
    handsFreeEnable: 'Use one-handed mode',
    handsFreeSpeakQuestion: 'Read questions aloud',
    handsFreeSpeakExplanation: 'Read explanations aloud',
    handsFreeSpeed: 'Reading speed',
    settingsTransfer: 'Transfer your progress',
    settingsAbout: 'About this app',
    aboutVersion: _enAboutVersion,
    coinTotal: 'Total',
    coinBreakdownTitle: 'Study coins earned this time',
    coinEventLabels: {
      'newQuestion': 'New questions',
      'coverageStep': 'Coverage up',
      'accuracyMilestone': 'Accuracy milestone',
      'accuracyBest': 'New personal best',
      'reviewCorrected': 'Mastered in review',
      'dailyConsult': "Today's consult",
      'mockDone': 'Mock exam taken',
      'mockPass': 'Mock exam passed',
      'mockBest': 'Mock exam personal best',
      'streak': 'Study streak',
      'passReport': 'Pass report',
    },
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
    passAskBody: 'What you tell us is used only on this device.',
    passNotYet: 'Not yet / waiting for results',
    passNotPassed: "I didn't pass this time",
    passPassed: 'I passed',
    passEncourageTitle: 'Good work',
    passEncourageBody:
        'Review your weak spots and try again. Your coins and outfits stay as they are.',
    passCongrats: 'Congratulations on passing!',
    passPrivacy:
        'The shared card contains no personal information such as your name.',
    passShare: 'Share',
    wardrobeTitle: 'Outfits & shop',
    wardrobeNote: 'Coins are earned by studying. Outfits are cosmetic only and do not affect your study content.',
    wardrobeInsufficient: 'Not enough coins. You earn them by studying',
    wardrobeAlreadyOwned: 'You already own this',
    wardrobeUnknown: 'This cannot be purchased',
    wardrobeCannotWear: 'You cannot wear this outfit right now',
    wardrobeWear: 'Wear',
    wardrobeWearing: 'Wearing',
    wardrobeCanWear: 'Available to wear',
    lockedNotPassed: 'Unlocked when you pass',
    lockedNoExamDate: 'Set your exam date to wear this',
    lockedNotReady: 'Unlocked when you reach your readiness goal',
    oshiMenuTooltip: 'Companion menu',
    oshiChoose: 'Choose companion',
    oshiPassReport: 'Report exam result',
    oshiDisplayNormal: 'Normal',
    oshiDisplaySmall: 'Show small',
    oshiDisplayHidden: 'Hide',
    oshiName: 'Companion',
    oshiHiddenNote: 'Your companion is hidden',
    oshiYours: 'Your companion',
    oshiTapHint: 'Tap your companion to hear a word',
    coinBalance: _enCoinBalance,
    wardrobePurchased: _enWardrobePurchased,
    wardrobePrice: _enWardrobePrice,
    lockedNotPurchased: _enLockedNotPurchased,
    passAskTitle: _enPassAskTitle,
    passCoin: _enPassCoin,
    passOutfit: _enPassOutfit,
    characterNames: {
      'standard': 'Uka',
      'kai': 'Kai',
      'mio': 'Mio',
      'moka': 'Moka',
      'mike': 'Mike',
    },
    characterRoles: {
      'standard': 'Flask assistant',
      'kai': 'Reliable senior',
      'mio': 'Cheerful junior',
      'moka': 'Easygoing buddy (dog)',
      'mike': 'Careful explainer (cat)',
    },
    feedbackTitleRequired: 'Please enter a title',
    feedbackDetailRequired: 'Please enter the details',
    feedbackTitleTooLong: _enTitleTooLong,
    feedbackDetailTooLong: _enDetailTooLong,
    correctLabel: 'Correct',
    incorrectLabel: 'Incorrect',
    sentenceSeparator: '. ',
    explanationTitle: 'Explanation',
    tabLabels: ['Home', 'Learn', 'Mock', 'Records', 'Settings'],
    readAloud: 'Read aloud',
    mockRecordTitle: 'Study record card',
    mockRecordNote: 'This is a mock exam record, not an actual pass. It contains no personal information such as your name.',
    mockRecordMessage: 'You beat the passing score!',
    sourceNote: _enSourceNote,
    sourceNoteChecked: _enSourceNoteChecked,
    mockRecordCert: _enMockRecordCert,
    shareCardBrand: 'Qualab',
    shareCardPassed: 'I passed!',
    shareDate: _enShareDate,
  );

  /// 言語コードから選ぶ。未対応の言語は日本語。
  /// 言語コードから選ぶ。アプリが用意した言語は [supported]（言語コード → 文言）で渡す。
  /// どちらにも無い言語は日本語。
  ///
  /// ```dart
  /// final zh = KitStrings.en.copyWith(languageCode: 'zh', coinTotal: '合计', /* … */);
  /// KitStrings.forLocale(locale, supported: {'zh': zh});
  /// ```
  static KitStrings forLocale(
    Locale locale, {
    Map<String, KitStrings> supported = const {},
  }) =>
      supported[locale.languageCode] ?? (locale.languageCode == 'en' ? en : ja);

  /// 最も近い [KitStringsScope] の文言。無ければ日本語。
  static KitStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.strings ??
      ja;
}

String _jaStreakDays(int d) => '$d日連続';
String _jaStreakSemantics(int d) => '連続学習 $d日';
String _jaCorrectOfTotal(int c, int t) => '$c / $t 問正解';
String _jaPassLine(int p) => '合格ライン $p%';
String _enStreakDays(int d) => '$d-day streak';
String _enStreakSemantics(int d) => 'Study streak $d days';
String _enCorrectOfTotal(int c, int t) => '$c of $t correct';
String _enPassLine(int p) => 'Passing line $p%';

String _jaPassAskTitle(String c) => '${c}の結果を教えてください';
String _enPassAskTitle(String c) => 'Tell us your $c result';
String _jaPassCoin(int a) => '学習コイン +$a';
String _enPassCoin(int a) => 'Study coins +$a';
String _jaPassOutfit(String n) => '「$n」を着られるようになりました';
String _enPassOutfit(String n) => 'You can now wear "$n"';

String _jaCoinBalance(int b) => '学習コイン $b';
String _enCoinBalance(int b) => 'Study coins $b';
String _jaWardrobePurchased(String n) => '${n}を購入しました';
String _enWardrobePurchased(String n) => 'Purchased $n';
String _jaWardrobePrice(int p) => '${p}コイン';
String _enWardrobePrice(int p) => '$p coins';
String _jaLockedNotPurchased(int p) => '${p}コインで購入できます';
String _enLockedNotPurchased(int p) => 'Buy for $p coins';

String _jaTitleTooLong(int m) => 'タイトルは$m文字以内で入力してください';
String _enTitleTooLong(int m) => 'Title must be $m characters or fewer';
String _jaDetailTooLong(int m) => '詳細は$m文字以内で入力してください';
String _enDetailTooLong(int m) => 'Details must be $m characters or fewer';

String _jaSourceNote(String s) => '出典: $s';
String _enSourceNote(String s) => 'Source: $s';
String _jaSourceNoteChecked(String s, String d) => '出典: $s（$d 確認）';
String _enSourceNoteChecked(String s, String d) => 'Source: $s (checked $d)';
String _jaMockRecordCert(String c) => '$c 模擬試験';
String _enMockRecordCert(String c) => '$c mock exam';

String _jaShareDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';
const _enShortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _enShareDate(DateTime d) => '${_enShortMonths[d.month - 1]} ${d.day}, ${d.year}';

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
///   labs: zhLabs,         // LabStrings（ラボ系ウィジェットの文言）
///   mascotLines: zhLines, // 推しのセリフ（口調 → セリフ集）
///   child: ...,
/// )
/// ```
class KitStringsScope extends InheritedWidget {
  const KitStringsScope({
    super.key,
    required this.strings,
    this.labs,
    this.mascotLines,
    required super.child,
  });

  final KitStrings strings;

  /// ラボ系ウィジェットの文言。null なら [LabStrings.ja]／[LabStrings.en]。
  final LabStrings? labs;

  /// 推しのセリフ。null、または口調が無ければ、既定のセリフ集。
  final Map<MascotTone, MascotLines>? mascotLines;

  /// 最も近い [KitStringsScope] の [labs]。無ければ null。
  static LabStrings? labsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.labs;

  /// 最も近い [KitStringsScope] の [mascotLines]。無ければ null。
  static Map<MascotTone, MascotLines>? mascotLinesOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.mascotLines;

  @override
  bool updateShouldNotify(KitStringsScope old) =>
      strings != old.strings ||
      labs != old.labs ||
      mascotLines != old.mascotLines;
}
