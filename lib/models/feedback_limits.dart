import '../ui_kit/kit_strings.dart';

/// フィードバックの入力上限。Firestore ルール（firestore.rules.example）と揃える。
class FeedbackLimits {
  const FeedbackLimits({
    this.titleMax = 100,
    this.descriptionMax = 2000,
    this.dailyMax = 5,
  });

  final int titleMax;
  final int descriptionMax;

  /// 端末あたり 1 日の送信上限。
  final int dailyMax;

  static const standard = FeedbackLimits();

  String? validateTitle(String? title, [KitStrings strings = KitStrings.ja]) {
    final t = (title ?? '').trim();
    if (t.isEmpty) return strings.feedbackTitleRequired;
    if (t.length > titleMax) return strings.feedbackTitleTooLong(titleMax);
    return null;
  }

  String? validateDescription(String? description,
      [KitStrings strings = KitStrings.ja]) {
    final d = (description ?? '').trim();
    if (d.isEmpty) return strings.feedbackDetailRequired;
    if (d.length > descriptionMax) return strings.feedbackDetailTooLong(descriptionMax);
    return null;
  }

  /// 問題があればユーザー向けメッセージ、なければ null。
  String? validate({
    required String title,
    required String description,
    KitStrings strings = KitStrings.ja,
  }) =>
      validateTitle(title, strings) ??
      validateDescription(description, strings);
}
