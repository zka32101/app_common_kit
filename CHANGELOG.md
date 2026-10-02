# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.1.1] - 2026-10-02

kanken 導入で見つかった不足分。

### Added
- 広告: `AdConfig.maxAdContentRating`（`AdContentRating`）と `nonPersonalizedAds`。児童向けアプリ（kanken）の既存設定を引き継ぐため
- 権利管理: `EntitlementService.offers()` / `purchaseOffer(offerId)` と `EntitlementOffer`（月額・年額など Offering の商品一覧と購入）

### Changed（破壊的）
- `EntitlementService` に抽象メソッド `offers` / `purchaseOffer` を追加。自前で実装しているアプリは対応が必要（同梱の `RevenueCatEntitlementService` / `FakeEntitlementService` は対応済み）

## [0.1.0] - 2026-10-02

### Added
- フィードバック: 送信フォーム、オフラインキュー、GitHub Issue 自動化用 Cloud Functions テンプレート
- フィードバック: 入力検証（タイトル100／本文2000文字）と端末あたり1日5件の上限（`FeedbackLimits`、`FeedbackNotifier.configure`）
- `firestore.rules.example`（自分の UID のみ作成・読み取り、上限あり）
- 権利管理: `EntitlementService` / `RevenueCatEntitlementService` / `FakeEntitlementService`、`noads`・`premium`（`adsHidden`）、購入前フック `BeforePurchase`、Riverpod Provider
- 広告ゲート: `AdGate`（UMP同意、インタースティシャルは `sessionEnd`／`mockExamResult` のみ、最短3分・日次5回、バナーは `home`／`result`／`weakDrill` のみ、有料時は非初期化、児童向けタグ、リリースでのテスト広告ID検知）
- GitHub Actions CI（analyze・test・functions ビルド）

### Notes
- RevenueCat／Google Mobile Ads の実装は実機・サンドボックス未検証（アプリ側で確認する）
- 返信画面・通知・Remote Config 連携は v0.2 以降
