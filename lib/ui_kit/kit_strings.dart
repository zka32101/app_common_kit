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
  );

  /// 言語コードから選ぶ。未対応の言語は日本語。
  static KitStrings forLocale(Locale locale) => locale.languageCode == 'en' ? en : ja;

  /// 最も近い [KitStringsScope] の文言。無ければ日本語。
  static KitStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitStringsScope>()?.strings ?? ja;
}

String _jaStreakDays(int d) => '$d日連続';
String _jaStreakSemantics(int d) => '連続学習 $d日';
String _jaCorrectOfTotal(int c, int t) => '$c / $t 問正解';
String _jaPassLine(int p) => '合格ライン $p%';
String _enStreakDays(int d) => '$d-day streak';
String _enStreakSemantics(int d) => 'Study streak $d days';
String _enCorrectOfTotal(int c, int t) => '$c of $t correct';
String _enPassLine(int p) => 'Passing line $p%';

/// 配下のキットのウィジェットが使う文言を切り替える。
///
/// ```dart
/// KitStringsScope(strings: KitStrings.forLocale(locale), child: ...)
/// ```
class KitStringsScope extends InheritedWidget {
  const KitStringsScope({super.key, required this.strings, required super.child});

  final KitStrings strings;

  @override
  bool updateShouldNotify(KitStringsScope old) => strings != old.strings;
}
