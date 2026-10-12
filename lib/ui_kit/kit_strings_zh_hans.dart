import 'kit_strings.dart';

// 簡体字中国語。機械翻訳の下書き。公開前に、母語話者の確認が要る。
// 用語: 推し=本命 / 学習コイン=学习币 / 合格=通过。

String _streakDays(int d) => '连续$d天';
String _minutesBadge(int m) => '约$m分钟';
String _streakSemantics(int d) => '连续学习 $d 天';
String _correctOfTotal(int c, int t) => '答对 $c / $t 题';
String _passLine(int p) => '及格线 $p%';
String _titleTooLong(int m) => '标题请在 $m 个字以内';
String _detailTooLong(int m) => '详情请在 $m 个字以内';
String _sourceNote(String s) => '出处：$s';
String _sourceNoteChecked(String s, String d) => '出处：$s（$d 已确认）';
String _aboutVersion(String v) => '版本 $v';

/// 簡体字中国語（`zh`）。
const kitStringsZhHans = KitStrings(
  languageCode: 'zh',
  reviewEnjoyTitle: '您喜欢这个应用吗？',
  updateRequiredTitle: '需要更新',
  updateRequiredBody: '此版本已无法使用，请更新到最新版本。',
  updateAvailableTitle: '有新版本',
  updateAvailableBody: '可以更新到最新版本。',
  updateNow: '更新',
  updateLater: '稍后',
  reviewYes: '是',
  reviewNo: '否',
  reviewLater: '稍后',
  purchaseTitle: '购买',
  purchasedPremium: '已购买高级版',
  purchasedNoAds: '已购买去广告',
  purchaseRestore: '恢复购买',
  purchaseSuccess: '购买成功。',
  purchaseCancelled: '已取消购买。',
  purchaseBlocked: '无法购买。',
  purchaseFailed: '购买失败。',
  restoreDone: '已恢复购买。',
  restoreNone: '没有可恢复的购买。',
  examDateTitle: '考试日期',
  examDateUnset: '未设置。输入后可使用考前复习模式。',
  examDateClear: '清除考试日期',
  minutesBadge: _minutesBadge,
  premiumLocked: '仅限高级版',
  settingsTitle: '设置',
  settingsTheme: '显示模式',
  themeSystem: '跟随设备',
  themeLight: '浅色',
  themeDark: '深色',
  settingsLanguage: '语言',
  settingsHandsFree: '单手・边做边学',
  handsFreeEnable: '使用单手模式',
  handsFreeSpeakQuestion: '朗读题目',
  handsFreeSpeakExplanation: '朗读解析',
  handsFreeSpeed: '朗读速度',
  settingsTransfer: '学习数据迁移（更换设备）',
  settingsAbout: '关于本应用',
  aboutVersion: _aboutVersion,
  errorMessage: '加载失败。请检查网络后重试。',
  retry: '重试',
  streakZero: '从今天开始吧',
  streakDays: _streakDays,
  streakSemantics: _streakSemantics,
  accuracy: '正确率',
  correctOfTotal: _correctOfTotal,
  passLineReached: '已达及格线',
  passLineNotYet: '还差一点。复习一下薄弱点吧',
  passLine: _passLine,
  again: '再来一次',
  close: '关闭',
  feedbackTitle: '意见反馈・问题报告',
  feedbackType: '类型',
  feedbackBug: '问题报告',
  feedbackFeature: '改进建议',
  feedbackOther: '其他',
  feedbackSubject: '标题',
  feedbackSubjectHint: '例：〇〇页面的按钮没有反应',
  feedbackDetail: '详情',
  feedbackDetailHint: '请尽量详细地描述情况',
  feedbackSubmit: '提交',
  feedbackSent: '已提交，谢谢！',
  feedbackFailed: '提交失败，请稍后再试。',
  feedbackTitleRequired: '请输入标题',
  feedbackDetailRequired: '请输入详情',
  feedbackTitleTooLong: _titleTooLong,
  feedbackDetailTooLong: _detailTooLong,
  correctLabel: '正确',
  incorrectLabel: '错误',
  sentenceSeparator: '。',
  explanationTitle: '解析',
  readAloud: '朗读',
  sourceNote: _sourceNote,
  sourceNoteChecked: _sourceNoteChecked,
);
