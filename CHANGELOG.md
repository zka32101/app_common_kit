# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.4.0] - 2026-10-03

※ 0.3.0（用語カード）・0.3.1（本文差し替え）はタグ未作成のまま main に入っているため、タグ `v0.4.0` にそれらも含まれる。

バイク免許コレで作った「ショップ・着替え」を共通化し、合格報告・準備完了・コイン内訳を追加。追加のみで、v0.2 の API に破壊的変更はない。

### 追加
- 資格 `UkalabCert.kanjiKentei`（漢字検定、分野: 言語・教育）。資格は17種、衣装は68着
- 衣装の状態管理: `outfitServiceProvider`（アプリで上書き）、`outfitProvider`／`OutfitNotifier`（`equip`・`reportPassed`・`markReady`）、`equippedOutfitProvider`
- `WardrobeScreen`: 資格1つぶんのショップ・着替え画面（コインで通常衣装を購入、ロック理由の表示）。バイクの `OshiWardrobeView` を一般化したもの
- `showPassReportDialog`: 合格報告。「合格しました」→ 学習コイン（資格ごとに1回）と合格記念の衣装を付与し、共有カード（個人情報なし）を見せる。「今回は合格できなかった」は責めず、コインも衣装も減らさない。`onShare` を渡すと共有ボタンが出る（OS の共有シートはアプリ側で実装。共通基盤は共有プラグインに依存しない）
- `ReadinessRule`: 準備完了の暫定判定（習得度0.8以上＋模擬試験の合格1回以上）。最短ルートプランナー完成までの暫定
- `CoinNotifier.takeRecent()` と `CoinState.recent`: セッション内の付与の履歴
- `CoinBreakdownCard`: 結果画面のコイン内訳（付与がなければ何も出さない）
- アイコン生成: シンボル `motorcycle`（仮）と、実アプリ用の定義 `specs/ukalab_apps.json`（`bike_license`）。検査（`check_icons.py`）を通る
- `firebase/`: 共通 Firebase（ukalab-prod／ukalab-dev）のルール・検査・手順。ルールの `examIds()` に `kanji_kentei` を追加

### 利用側の注意
- `OutfitService` をアプリで作って `outfitServiceProvider` を上書きする（`SharedPreferencesOutfitStore(appId)`）。`CoinService` の `shop` には `OutfitCatalog.shopItems([cert])` を渡す
- 合格記念・準備完了の衣装を解放する入口は、アプリ側が `showPassReportDialog`／`outfitProvider.notifier.markReady` を呼ぶ
- 新しい資格を足したときは、`firebase/firestore.rules` の `examIds()` にも id を追加して配備する

## [0.3.1] - 2026-10-03

`QuestionCard`・`ExplanationPanel` に、本文を差し替えられる後方互換のオプションを追加。追加のみで、v0.3.0 の API に破壊的変更はない。

### 追加
- `QuestionCard.textWidget`: 問題文の表示を `TappableTermText` などに差し替えられる。省略すれば従来どおり `text` をそのまま表示する
- `ExplanationPanel.bodyWidget`: 解説文の表示を同様に差し替えられる。省略すれば従来どおり `body` をそのまま表示する

## [0.3.0] - 2026-10-03

専門用語の解説（決定50「専門用語の解説（全アプリ共通）」）のUI部品。追加のみで、v0.2 の API に破壊的変更はない。

### 追加
- `TermCard`: 用語カード（①ひとことで言うと→②正確な意味→③たとえ話→④よくある間違い→⑤関連用語→⑥関連問題の順に表示）
- `showTermCard`: `TermCard` をボトムシートで開くヘルパー
- `TappableTermText`: 問題文・解説文などの本文中の用語に下線つきのタップ領域を重ねるテキスト部品

## [Unreleased]

### 追加
- `showMockRecordDialog`: 模擬試験で合格点を超えたときの「学習の記録カード」（保守版 v0.4.3 と同じ内容を main にも取り込み）。コインも衣装も付けない
- `MasteryInput.fromCounts()`／`MasteryInput.fromLogs()`: 件数・回答ログから習得度の入力を作る共通計算（保守版 v0.4.2 と同じ内容を main にも取り込み）

### 修正
- `ReadinessProgressCard`: 進捗バーの色を明示（保守版 v0.4.4 と同じ内容を main にも取り込み）。0% でもバー全体が塗られて見える問題の修正

## [0.4.1] - 2026-10-04（保守版・ブランチ `release/0.4`）

v0.4.0 に「準備完了までの進み具合」（`ReadinessProgress`／`ReadinessProgressCard`）だけを足した版。main の他の追加は含まない。v0.8.0 は `cloud_firestore` 5系以上を要求し、4系の漢字マスター検定が使えないため、両アプリ（バイク免許コレ・漢字マスター検定）は v0.4.1 を使う。v0.8.0 に上げる場合は、先にアプリ側の Firebase を5系へ上げること。また v0.8.0 の `adGateProvider` はバイク免許コレ自前の同名プロバイダと衝突する（import で `hide` が要る）。

## [0.8.0] - 2026-10-04

※ v0.4.0 以降、別セッション（G検定・型部品）の追加（#24〜#31: 予測→実行、答案の添削、最短ルートプランナー、失敗図鑑、AdGate、ExamStatsService、用語マップ、評価指標ラボ）が、タグ・本ファイルへの記載なしで main に入っている。タグ `v0.8.0` にそれらも含まれる（pubspec は 0.7.0 まで進んでいた）。追加のみで破壊的変更はない。

### 追加
- `ReadinessRule.progress()` と `ReadinessProgress`（習得度の達成率、あと何%、模擬試験の合格が要るか）、`ReadinessProgressCard`（「準備完了まで」の進み具合カード。責める表現なし）
- `firebase/`: うかラボ共通 Firebase（`ukalab-prod`／`ukalab-dev`）のルール、ルール検査（`test_rules.py`）、設定、手順。ライブラリ本体（lib/）は変更なし

## [0.2.1] - 2026-10-03

### 追加
- `UkalabCert.bikeLicense`（運転免許（二輪）、分野: 技術・安全）。資格は16種、衣装は64着になる。追加のみで破壊的変更なし

## [0.2.0] - 2026-10-02

v0.2 追加仕様 §1〜6（テーマ・共通UI部品・推し・学習コイン・衣装と資格連動・アイコン生成）。§7（学習体験の型）は yourwish_kentei 側で v0.3 以降。

### 利用側の注意
- 追加のみで、v0.1 の API に破壊的変更はない
- 暫定値: 習得度の式と段階の境目（マスコット仕様で未決）、コインの獲得量・価格、通常衣装の価格（300）。いずれも差し替え可能
- 設計書の success 色（ライト）は文字としては AA に届かない。✓アイコンと文言を併記すること

### Added
- テーマ: `UkalabTheme.light/dark(field:, cert:)`。分野（`UkalabField` 5種）と資格（`UkalabCert` 15種。決定77）から ThemeData を生成。色トークン `UkalabPalette`、コントラスト比 `contrastRatio`
- 文字サイズ（本文16／解説17・行間1.6／見出し20・24／注釈13）、角丸（カード16／ボタン12）、タップ領域44pt以上を共通化
- 会計・経営のライトは warning を #8A6100 に差し替え
- 共通UI部品（ui_kit）: `QuestionCard`／`ChoiceTile`（idle・selected・correct・incorrect。正誤は✓／✕＋文言）／`ExplanationPanel`（出典つき）／`ProgressRing`／`StreakBadge`／`ResultSummary`／`EmptyState`・`ErrorState`／`UkalabShell`（下部5タブ）
- 学習コイン（coin）: `CoinService`（獲得 `grant`／購入 `purchase`／装備）、`CoinEvent` 11種、`CoinRules`（数値は差し替え可）、追記専用の `CoinLedger`（残高は台帳の合計。同じ行は統合しても二重にならない）、`CoinStore`（端末内。財布は**アプリごと**）、Riverpod の `coinProvider`、`ShopItem`・`validateShop`。有償・広告視聴での付与は実装しない
- 推し（mascot）: `CharacterPack`（id・名前・口調・画像ビルダー・分野差し色・署名）、標準キャラ「フラスコの助手」のコード描画（Lv1〜5で装いが重なる／よろこびの表情／試験日が近いとはちまき）、`MascotWidget`（非表示・小さく・動きを減らす設定に対応、吹き出し）、`MasteryModel`（習得度＝網羅率×正答率、段階の境目と係数は差し替え可、次の段階まであと何問）、`MascotDayState`（表情・「おかえり」・試験日の装い）、`MascotLines`（セリフ集）と禁止表現チェック（責める・消える・恋愛依存）
- 衣装・資格連動（outfit）: `OutfitCatalog`（15資格×4着: 通常・合格記念・試験日・準備完了）、`OutfitService`（合格報告で記念衣装、最短ルート達成で準備完了、試験日設定で試験日の装い。通常衣装はコイン購入）、標準キャラの衣装描画（分野の小物5種・メダル・準備完了の旗・はちまき）、`PassShareCard`（推しと合格の共有カード。個人情報なし）と `captureShareCard`（PNG化）。`MascotWidget` に `outfit`・`animate`
- アイコン生成（tools/icon_gen）: 試験名・シンボルSVG・資格IDから 1024px PNG、Android adaptive の前景／背景、最小サイズ用（上段なし・シンボル拡大）を出力。色は `ukalab_palette.dart` から読む（二重管理しない）。`check_icons.py` で サイズ・コントラスト（4.5:1）・要素の重なり・端の余白・adaptive の中央66%・最小サイズ版の上段なしを検査。CI に `icons` ジョブ（フォント fonts-noto-cjk）。サンプル6種（G検定・乙4・簿記3・電験3・ITパス・診断士）
- テスト: 全部品を文字拡大200%・ライト／ダークで表示、タップ領域44pt、Semantics
- テスト: 全トークンのコントラスト（AA未満は失敗）、資格15色×ライト/ダーク、文字拡大200%

## [0.1.2] - 2026-10-02

### Fixed
- `google_mobile_ads` の下限を `>=4.0.0` から `>=5.3.1` に修正。UMP の `ConsentForm.loadAndShowConsentFormIfRequired` / `ConsentInformation.canRequestAds` が 4.0.0 に無く、kanken(4.0.0)でビルドが通らなかった。5.3.1 で kanken の debug APK ビルド成功を確認

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
