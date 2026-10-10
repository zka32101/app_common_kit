/// ストアのレビュー画面の窓口。実処理（`in_app_review` など）をアプリが実装して渡す。
/// キットはレビューのプラグインに依存しない（`SpeechBackend` と同じ作り）。
abstract class ReviewBackend {
  /// この端末で、アプリ内のレビュー画面を出せるか。
  Future<bool> isAvailable();

  /// アプリ内のレビュー画面を出す。OS 側にも回数の制限があり、出ないことがある（結果は分からない）。
  Future<void> requestReview();
}

/// テスト・プレビュー用。呼ばれた回数を記録するだけ。
class FakeReviewBackend implements ReviewBackend {
  FakeReviewBackend({this.available = true});

  bool available;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requestCount++;
}
