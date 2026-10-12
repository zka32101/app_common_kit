import 'kit_strings.dart';

// 韓国語。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=최애 / 学習コイン=학습 코인 / 合格=합격。

String _streakDays(int d) => '$d일 연속';
String _minutesBadge(int m) => '약 $m분';
String _streakSemantics(int d) => '연속 학습 $d일';
String _correctOfTotal(int c, int t) => '$t문제 중 $c문제 정답';
String _passLine(int p) => '합격선 $p%';
String _titleTooLong(int m) => '제목은 $m자 이내로 입력해 주세요';
String _detailTooLong(int m) => '상세 내용은 $m자 이내로 입력해 주세요';
String _sourceNote(String s) => '출처: $s';
String _sourceNoteChecked(String s, String d) => '출처: $s ($d 확인)';
String _aboutVersion(String v) => '버전 $v';

/// 韓国語（`ko`）。
const kitStringsKo = KitStrings(
  languageCode: 'ko',
  reviewEnjoyTitle: '앱이 마음에 드시나요?',
  updateRequiredTitle: '업데이트가 필요합니다',
  updateRequiredBody: '이 버전은 더 이상 사용할 수 없습니다. 최신 버전으로 업데이트해 주세요.',
  updateAvailableTitle: '새로운 버전이 있습니다',
  updateAvailableBody: '최신 버전으로 업데이트할 수 있습니다.',
  updateNow: '업데이트',
  updateLater: '나중에',
  reviewYes: '네',
  reviewNo: '아니요',
  reviewLater: '나중에',
  purchaseTitle: '구매',
  purchasedPremium: '프리미엄을 구매했습니다',
  purchasedNoAds: '광고 제거를 구매했습니다',
  purchaseRestore: '구매 복원',
  purchaseSuccess: '구매했습니다.',
  purchaseCancelled: '구매를 취소했습니다.',
  purchaseBlocked: '구매할 수 없습니다.',
  purchaseFailed: '구매에 실패했습니다.',
  restoreDone: '구매를 복원했습니다.',
  restoreNone: '복원할 구매 내역이 없습니다.',
  examDateTitle: '시험일',
  examDateUnset: '설정되지 않음. 입력하면 시험 직전 복습 모드를 사용할 수 있어요.',
  examDateClear: '시험일 해제',
  minutesBadge: _minutesBadge,
  premiumLocked: '프리미엄 전용',
  settingsTitle: '설정',
  settingsTheme: '화면 모드',
  themeSystem: '기기 설정',
  themeLight: '라이트',
  themeDark: '다크',
  settingsLanguage: '언어',
  settingsHandsFree: '한 손・틈틈이 학습',
  handsFreeEnable: '한 손 모드 사용',
  handsFreeSpeakQuestion: '문제 읽어 주기',
  handsFreeSpeakExplanation: '해설 읽어 주기',
  handsFreeSpeed: '읽는 속도',
  settingsTransfer: '학습 데이터 이전 (기기 변경)',
  settingsAbout: '앱 정보',
  aboutVersion: _aboutVersion,
  errorMessage: '불러오지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.',
  retry: '다시 시도',
  streakZero: '오늘부터 시작해 봐요',
  streakDays: _streakDays,
  streakSemantics: _streakSemantics,
  accuracy: '정답률',
  correctOfTotal: _correctOfTotal,
  passLineReached: '합격선 도달',
  passLineNotYet: '조금만 더! 약점을 복습해 봐요',
  passLine: _passLine,
  again: '다시 하기',
  close: '닫기',
  feedbackTitle: '의견・오류 신고',
  feedbackType: '유형',
  feedbackBug: '오류 신고',
  feedbackFeature: '개선 요청',
  feedbackOther: '기타',
  feedbackSubject: '제목',
  feedbackSubjectHint: '예: 〇〇 화면에서 버튼이 반응하지 않아요',
  feedbackDetail: '상세 내용',
  feedbackDetailHint: '상황을 가능한 한 자세히 알려 주세요',
  feedbackSubmit: '보내기',
  feedbackSent: '보냈습니다. 감사합니다!',
  feedbackFailed: '보내지 못했습니다. 잠시 후 다시 시도해 주세요.',
  feedbackTitleRequired: '제목을 입력해 주세요',
  feedbackDetailRequired: '상세 내용을 입력해 주세요',
  feedbackTitleTooLong: _titleTooLong,
  feedbackDetailTooLong: _detailTooLong,
  correctLabel: '정답',
  incorrectLabel: '오답',
  sentenceSeparator: '. ',
  explanationTitle: '해설',
  readAloud: '읽어 주기',
  sourceNote: _sourceNote,
  sourceNoteChecked: _sourceNoteChecked,
);
