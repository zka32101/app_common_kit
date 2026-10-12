import 'kit_strings.dart';

// 繁体字中国語（台湾・香港向け）。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=本命 / 学習コイン=學習幣 / 合格=通過。

String _streakDays(int d) => '連續$d天';
String _minutesBadge(int m) => '約$m分鐘';
String _streakSemantics(int d) => '連續學習 $d 天';
String _correctOfTotal(int c, int t) => '答對 $c / $t 題';
String _passLine(int p) => '及格線 $p%';
String _titleTooLong(int m) => '標題請在 $m 個字以內';
String _detailTooLong(int m) => '詳情請在 $m 個字以內';
String _sourceNote(String s) => '出處：$s';
String _sourceNoteChecked(String s, String d) => '出處：$s（$d 已確認）';
String _aboutVersion(String v) => '版本 $v';

/// 繁体字中国語（`zh-Hant`）。
const kitStringsZhHant = KitStrings(
  languageCode: 'zh-Hant',
  reviewEnjoyTitle: '您喜歡這個應用程式嗎？',
  updateRequiredTitle: '需要更新',
  updateRequiredBody: '此版本已無法使用，請更新至最新版本。',
  updateAvailableTitle: '有新版本',
  updateAvailableBody: '可以更新至最新版本。',
  updateNow: '更新',
  updateLater: '稍後',
  reviewYes: '是',
  reviewNo: '否',
  reviewLater: '稍後',
  purchaseTitle: '購買',
  purchasedPremium: '已購買進階版',
  purchasedNoAds: '已購買移除廣告',
  purchaseRestore: '恢復購買',
  purchaseSuccess: '購買成功。',
  purchaseCancelled: '已取消購買。',
  purchaseBlocked: '無法購買。',
  purchaseFailed: '購買失敗。',
  restoreDone: '已恢復購買。',
  restoreNone: '沒有可恢復的購買項目。',
  examDateTitle: '考試日期',
  examDateUnset: '尚未設定。輸入後即可使用考前複習模式。',
  examDateClear: '清除考試日期',
  minutesBadge: _minutesBadge,
  premiumLocked: '僅限進階版',
  settingsTitle: '設定',
  settingsTheme: '顯示模式',
  themeSystem: '跟隨裝置',
  themeLight: '淺色',
  themeDark: '深色',
  settingsLanguage: '語言',
  settingsHandsFree: '單手・邊做邊學',
  handsFreeEnable: '使用單手模式',
  handsFreeSpeakQuestion: '朗讀題目',
  handsFreeSpeakExplanation: '朗讀解析',
  handsFreeSpeed: '朗讀速度',
  settingsTransfer: '學習資料轉移（更換裝置）',
  settingsAbout: '關於本應用程式',
  aboutVersion: _aboutVersion,
  errorMessage: '載入失敗。請檢查網路連線後再試一次。',
  retry: '重試',
  streakZero: '從今天開始吧',
  streakDays: _streakDays,
  streakSemantics: _streakSemantics,
  accuracy: '正確率',
  correctOfTotal: _correctOfTotal,
  passLineReached: '已達及格線',
  passLineNotYet: '還差一點。複習一下弱點吧',
  passLine: _passLine,
  again: '再來一次',
  close: '關閉',
  feedbackTitle: '意見回饋・問題回報',
  feedbackType: '類型',
  feedbackBug: '問題回報',
  feedbackFeature: '改善建議',
  feedbackOther: '其他',
  feedbackSubject: '標題',
  feedbackSubjectHint: '例：〇〇頁面的按鈕沒有反應',
  feedbackDetail: '詳情',
  feedbackDetailHint: '請盡量詳細地描述狀況',
  feedbackSubmit: '送出',
  feedbackSent: '已送出，謝謝！',
  feedbackFailed: '送出失敗，請稍後再試。',
  feedbackTitleRequired: '請輸入標題',
  feedbackDetailRequired: '請輸入詳情',
  feedbackTitleTooLong: _titleTooLong,
  feedbackDetailTooLong: _detailTooLong,
  correctLabel: '正確',
  incorrectLabel: '錯誤',
  sentenceSeparator: '。',
  explanationTitle: '解析',
  readAloud: '朗讀',
  sourceNote: _sourceNote,
  sourceNoteChecked: _sourceNoteChecked,
);
