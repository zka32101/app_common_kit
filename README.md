# app_common_kit

Petit Works apps 全体で使う共通ユーティリティパッケージです。
`shared_core`（小学コレシリーズ専用）や `cross_promo_kit`（クロスプロモーション専用）とは異なり、
**小学コレシリーズに限らない全アプリ**が対象です。

## 位置づけ

| パッケージ | 対象 | 依存方針 |
|---|---|---|
| `shared_core` | 小学コレシリーズ（7アプリ）専用 | ゲーミフィケーション・Firebase 一式 |
| `cross_promo_kit` | 全アプリ横断のクロスプロモーション専用 | `firebase_remote_config` + `url_launcher` のみ |
| `app_common_kit`（本リポジトリ） | 全アプリ横断の共通基盤 | 機能ごとに最小限（下記参照） |

## 設計方針

- `cross_promo_kit` と同じく、依存は機能ごとに最小限に絞ります。
- 例外として権利管理は `purchases_flutter`、広告ゲートは `google_mobile_ads` に依存します（広めのレンジ指定）。
- Firebase（`cloud_firestore` / `firebase_auth` 等）には直接依存しません。
  実データの送受信は各アプリ側がコールバックとして注入する設計です
  （`shared_core` の「型・共通ロジックは shared_core、実データ/実処理はアプリ側」という
  パターンを踏襲）。
- 各アプリの `pubspec.yaml` から git dependency として参照します。

```yaml
dependencies:
  app_common_kit:
    git:
      url: https://github.com/zka32101/app_common_kit.git
      ref: v0.1.0   # タグ固定。main は参照しない
```

## 構成

```
lib/
  app_common_kit.dart          # エントリポイント（公開API）
  models/
    feedback_model.dart        # フィードバック（バグ報告・改善要望）モデル
    feedback_limits.dart       # 入力上限（文字数・1日の回数）と検証
  providers/
    feedback_provider.dart     # FeedbackNotifier（送信・オフラインキュー管理）
  widgets/
    feedback_form_page.dart    # フィードバック送信フォーム画面
  entitlement/                 # 権利管理（noads / premium）
  ads/                         # 広告ゲート（UMP・頻度制御）
firestore.rules.example        # フィードバック用ルール雛形
functions/                     # Cloud Functions テンプレート（各アプリの
  src/                         # Firebase プロジェクトにコピーしてデプロイする）
    index.ts
    feedback-github-issue.ts   # feedback コレクション onCreate → GitHub Issue 自動作成
```

## 機能1: フィードバック機能（バグ報告・改善要望）

### 使い方（各アプリ）

#### Step 1: main.dart 等で送信処理を注入

```dart
import 'package:app_common_kit/app_common_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

ref.read(feedbackProvider.notifier).setSubmitHandler((report) async {
  await FirebaseFirestore.instance
      .collection('feedback')
      .doc(report.id)
      .set(report.toJson());
});

// アプリ起動時、未送信分の再送信を試みる
await ref.read(feedbackProvider.notifier).retryPendingReports();
```

#### Step 2: フォーム画面を開く

```dart
import 'package:app_common_kit/app_common_kit.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const FeedbackFormPage(
      appName: 'kokugo-kore',
      appVersion: '1.2.0',
      userId: null, // 匿名認証UID等があれば渡す（任意）
    ),
  ),
);
```

送信に失敗した場合は `SharedPreferences` にローカルキューとして保存され、
次回 `retryPendingReports()` 呼び出し時（通常はアプリ起動時）に再送信されます。

## 機能2: GitHub Issue 自動化（Cloud Functions, 半自動連携）

`functions/` に、Firestore の `feedback` コレクションへの書き込みを検知して
GitHub Issue を自動作成する Cloud Functions のテンプレートを同梱しています。
各アプリは Firebase プロジェクトが別々（マルチプロジェクト構成）のため、
**このコードを各アプリの `functions/` にコピーしてデプロイする**運用とします
（npm パッケージとして配布するほどの規模ではないため、テンプレートコピー方式）。

### 動作

1. アプリ側で `feedbackProvider.notifier.setSubmitHandler()` が Firestore の
   `feedback` コレクションに `FeedbackReport.toJson()` を書き込む
2. `onFeedbackCreated`（`functions/src/feedback-github-issue.ts`）が onCreate を検知
3. `FeedbackType` を label にマッピング（`bug`→`bug`, `feature`→`enhancement`,
   `other`→`feedback`）し、GitHub Issues API で Issue を作成
4. 作成した Issue の URL を同じ Firestore ドキュメントの `githubIssueUrl` に書き戻し、
   `status` を `'reviewing'` に更新（アプリ側からも対応状況を参照可能）

### 各アプリへの導入手順

#### Step 1: functions/ にコピー

対象アプリの Firebase Functions プロジェクト（無ければ `firebase init functions` で作成）に、
本リポジトリの `functions/src/feedback-github-issue.ts` をコピーし、`src/index.ts` から
export する。

```ts
// アプリ側 functions/src/index.ts
export { onFeedbackCreated } from './feedback-github-issue';
```

#### Step 2: GitHub Issue 作成先リポジトリと PAT を設定

Issue を作成するリポジトリは `GITHUB_OWNER` / `GITHUB_REPO` 環境変数（アプリごとに値が異なる）、
認証は Secret の `GITHUB_TOKEN` で設定する。PAT は対象リポジトリへの
**"Issues: Read and write" のみを持つ fine-grained PAT** を推奨（最小権限）。

```bash
firebase functions:secrets:set GITHUB_TOKEN
# 環境変数は functions/.env.<project-id> もしくは Secret Manager で管理
echo "GITHUB_OWNER=zka32101" >> .env.<project-id>
echo "GITHUB_REPO=kokugo-kore" >> .env.<project-id>
```

#### Step 3: デプロイ

```bash
cd functions
npm install
npm run build
npm run deploy
```

### ローカルでの動作確認

```bash
cd functions
npm install
npm run build   # tsc の型チェック・コンパイルのみ確認可能
```

実際の GitHub Issue 作成の動作確認は、Firebase Emulator Suite 上で
`feedback` コレクションにドキュメントを作成して確認する。

## 機能3: 権利管理（Entitlement）

権利名は `noads`（広告なし・買い切り）と `premium`（期間付き／買い切り）。どちらかを持てば `adsHidden == true`。

```dart
final entitlement = await RevenueCatEntitlementService.init(
  publicSdkKey: rcPublicKey, // 公開SDKキー。コミットしない
  beforePurchase: (productId) => showParentalGate(context), // 子ども向けのみ
);

runApp(ProviderScope(
  overrides: [entitlementServiceProvider.overrideWithValue(entitlement)],
  child: const MyApp(),
));

// UI
final hidden = ref.watch(adsHiddenProvider);
await entitlement.purchase('noads_480'); // PurchaseOutcome を返す
await entitlement.restore();
```

- 端末移行（匿名→Google/Apple連携）は `logIn(appUserId)` で RevenueCat の ID を引き継ぐ。
- 期間パス（30日／90日）は非更新型、買い切りは非消耗型。期限は RevenueCat の Entitlement で管理。
- テストでは `FakeEntitlementService` を使う。

## 機能4: 広告ゲート（AdGate）

```dart
final ads = await AdGate.init(
  config: AdConfig(
    unitIds: AdUnitIds(banner: ..., interstitial: ..., rewarded: ...), // 本番IDは引数で渡す
    childDirected: false, // 子ども向けアプリは true
  ),
  adsHidden: () => entitlement.state.adsHidden,
);

await ads.maybeShowInterstitial(InterstitialTrigger.sessionEnd); // 学習セッション終了時
await ads.maybeShowInterstitial(InterstitialTrigger.mockExamResult); // 模擬試験の結果後
Widget banner = ads.banner(BannerPlacement.home); // home / result / weakDrill のみ
final rewarded = await ads.showRewarded(); // 「今日の特訓10問」追加など
```

- 出題中・解説表示中の契機/場所は型として存在しない（呼べない）。
- インタースティシャルは最短3分間隔・1日5回（暫定。`updateRules(AdRules(...))` で上書き）。
- 有料（`adsHidden`）の間は広告SDKを初期化しない。
- リリースビルドで Google のテスト広告IDを使うと `StateError`。
- iOS の ATT 文言は UMP の同意フォームで扱う。

## バージョン運用

- アプリは `ref: vX.Y.Z` で参照する。タグは削除・付け替えしない。修正は新タグで出す。
- 戻す手順: `ref` を前のタグへ → `flutter pub get` → ビルド確認。
- 変更は [CHANGELOG.md](CHANGELOG.md) に記録。破壊的変更は major を上げる。
- ローカル開発は `pubspec_overrides.yaml`（コミットしない）で path 参照に切り替える。
