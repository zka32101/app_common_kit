import 'package:flutter/widgets.dart';

/// キット内蔵ウィジェットの既定文言（日本語・英語）。
///
/// 既定は日本語。端末の言語には自動で従わず、アプリが [KitStringsScope] で明示したときだけ切り替わる
/// （既存アプリの表示が勝手に変わらない）。個別の引数で文言を渡した場合は、そちらが優先される。
@immutable
class KitStrings {
  const KitStrings({
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
    required this.feedbackTitleRequired,
    required this.feedbackDetailRequired,
    required this.feedbackTitleTooLong,
    required this.feedbackDetailTooLong,
  });

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
  final String feedbackTitleRequired;
  final String feedbackDetailRequired;
  final String Function(int max) feedbackTitleTooLong;
  final String Function(int max) feedbackDetailTooLong;

  static const ja = KitStrings(
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
    feedbackTitleRequired: 'タイトルを入力してください',
    feedbackDetailRequired: '詳細を入力してください',
    feedbackTitleTooLong: _jaTitleTooLong,
    feedbackDetailTooLong: _jaDetailTooLong,
  );

  static const en = KitStrings(
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
    feedbackTitleRequired: 'Please enter a title',
    feedbackDetailRequired: 'Please enter the details',
    feedbackTitleTooLong: _enTitleTooLong,
    feedbackDetailTooLong: _enDetailTooLong,
  );

  /// 言語コードから選ぶ。未対応の言語は日本語。
  static KitStrings forLocale(Locale locale) =>
      locale.languageCode == 'en' ? en : ja;

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

/// 配下のキットのウィジェットが使う文言を切り替える。
///
/// ```dart
/// KitStringsScope(strings: KitStrings.forLocale(locale), child: ...)
/// ```
class KitStringsScope extends InheritedWidget {
  const KitStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final KitStrings strings;

  @override
  bool updateShouldNotify(KitStringsScope old) => strings != old.strings;
}
