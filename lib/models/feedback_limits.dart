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

  String? validateTitle(String? title) {
    final t = (title ?? '').trim();
    if (t.isEmpty) return 'タイトルを入力してください';
    if (t.length > titleMax) return 'タイトルは$titleMax文字以内で入力してください';
    return null;
  }

  String? validateDescription(String? description) {
    final d = (description ?? '').trim();
    if (d.isEmpty) return '詳細を入力してください';
    if (d.length > descriptionMax) return '詳細は$descriptionMax文字以内で入力してください';
    return null;
  }

  /// 問題があればユーザー向けメッセージ、なければ null。
  String? validate({required String title, required String description}) =>
      validateTitle(title) ?? validateDescription(description);
}
