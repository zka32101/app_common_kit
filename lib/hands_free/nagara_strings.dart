import 'package:flutter/foundation.dart';

/// ながらセッション（画面点灯中の自動進行ハンズフリー学習）の文言。
///
/// [KitStrings.nagara] から読む。ja / en を内蔵し、ko・zh は日本語のまま
/// （母語話者の確認後に足す）。責める言い方（間違い・遅れ・急かす）は使わない。
@immutable
class NagaraStrings {
  const NagaraStrings({
    required this.positionLabel,
    required this.remainingLabel,
    required this.phaseReadingQuestion,
    required this.phaseWaitingAnswer,
    required this.phaseReadingAnswer,
    required this.phasePausedBetween,
    required this.phasePaused,
    required this.phaseFinished,
    required this.pause,
    required this.resume,
    required this.skip,
    required this.stop,
    required this.close,
    required this.tapHint,
    required this.speechUnavailable,
    required this.chosenLabel,
    required this.correctSpoken,
    required this.checkSpoken,
    required this.unansweredSpoken,
    required this.answerIsSpoken,
    required this.explanationSpoken,
    required this.finishedSummary,
    required this.restSuggestion,
    required this.settingsThinkSeconds,
    required this.settingsBetweenSeconds,
    required this.settingsAutoAdvance,
    required this.secondsOption,
  });

  /// 「問題 3 / 10」
  final String Function(int index, int total) positionLabel;

  /// 「残り 7 問」
  final String Function(int remaining) remainingLabel;

  final String phaseReadingQuestion;
  final String phaseWaitingAnswer;
  final String phaseReadingAnswer;
  final String phasePausedBetween;
  final String phasePaused;
  final String phaseFinished;

  final String pause;
  final String resume;
  final String skip;
  final String stop;
  final String close;

  /// 「選択肢をタップして答えることもできます。」
  final String tapHint;

  /// 音声が使えず、画面だけで進めているときの案内。
  final String speechUnavailable;

  /// 選んだ答えの印（不正解という言葉は使わない）。
  final String chosenLabel;

  /// 正解したときに読む文。
  final String correctSpoken;

  /// タップで答えて正解でなかったときに読む文の頭。
  final String checkSpoken;

  /// 考える時間が終わったときに読む文の頭。
  final String unansweredSpoken;

  /// 「正解は ア、〜です。」
  final String Function(String label, String text) answerIsSpoken;

  /// 解説の前に読む一言。
  final String explanationSpoken;

  /// 「10 問のうち 7 問、正解でした。」
  final String Function(int correct, int total) finishedSummary;

  /// 上限問数に達したときの休憩の声かけ。
  final String restSuggestion;

  final String settingsThinkSeconds;
  final String settingsBetweenSeconds;
  final String settingsAutoAdvance;

  /// 「5 秒」
  final String Function(int seconds) secondsOption;

  static const ja = NagaraStrings(
    positionLabel: _jaPosition,
    remainingLabel: _jaRemaining,
    phaseReadingQuestion: '問題を読んでいます',
    phaseWaitingAnswer: '考える時間です',
    phaseReadingAnswer: '答えを読んでいます',
    phasePausedBetween: '次の問題の前のひと息です',
    phasePaused: '一時停止中です',
    phaseFinished: 'おつかれさまでした',
    pause: '一時停止',
    resume: '再開',
    skip: 'スキップ',
    stop: '終了',
    close: 'とじる',
    tapHint: '選択肢をタップして答えることもできます。',
    speechUnavailable: '音声が使えないため、画面だけで進めています。',
    chosenLabel: 'えらんだ答え',
    correctSpoken: 'そのとおり。正解です。',
    checkSpoken: 'いっしょに確認しましょう。',
    unansweredSpoken: 'いっしょに確認しましょう。',
    answerIsSpoken: _jaAnswerIs,
    explanationSpoken: '解説。',
    finishedSummary: _jaSummary,
    restSuggestion: 'ここでひと休みしましょう。目と耳を休めると、また聞きやすくなります。',
    settingsThinkSeconds: '考える時間',
    settingsBetweenSeconds: '次の問題までの間',
    settingsAutoAdvance: '自動で次へ進む',
    secondsOption: _jaSeconds,
  );

  static const en = NagaraStrings(
    positionLabel: _enPosition,
    remainingLabel: _enRemaining,
    phaseReadingQuestion: 'Reading the question',
    phaseWaitingAnswer: 'Time to think',
    phaseReadingAnswer: 'Reading the answer',
    phasePausedBetween: 'A short breather before the next one',
    phasePaused: 'Paused',
    phaseFinished: 'Nice work today',
    pause: 'Pause',
    resume: 'Resume',
    skip: 'Skip',
    stop: 'End',
    close: 'Close',
    tapHint: 'You can also tap a choice to answer.',
    speechUnavailable: 'Voice is not available, so the session runs on screen only.',
    chosenLabel: 'Your choice',
    correctSpoken: 'That is right.',
    checkSpoken: "Let's check it together.",
    unansweredSpoken: "Let's check it together.",
    answerIsSpoken: _enAnswerIs,
    explanationSpoken: 'Explanation.',
    finishedSummary: _enSummary,
    restSuggestion: 'Time for a short break. Rest your eyes and ears, then come back fresh.',
    settingsThinkSeconds: 'Thinking time',
    settingsBetweenSeconds: 'Pause before the next question',
    settingsAutoAdvance: 'Move on automatically',
    secondsOption: _enSeconds,
  );
}

String _jaPosition(int i, int t) => '問題 $i / $t';
String _jaRemaining(int n) => '残り $n 問';
String _jaAnswerIs(String l, String t) => '正解は$l、$tです。';
String _jaSummary(int c, int t) => '$t 問のうち $c 問、正解でした。';
String _jaSeconds(int s) => '$s 秒';

String _enPosition(int i, int t) => 'Question $i / $t';
String _enRemaining(int n) => '$n left';
String _enAnswerIs(String l, String t) => 'The answer is $l, $t.';
String _enSummary(int c, int t) => '$c of $t correct.';
String _enSeconds(int s) => '$s sec';
