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

## 共通の設定画面（`SettingsScreen`）

設定タブの完成品。全アプリで同じ並びの設定画面になる。項目はそれぞれ任意で、引数で出し分ける。

```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
  appName: 'ITパスポート',
  appVersion: '1.2.0',
  examDate: examDate,                 // 渡すと「受験日」を出す
  onExamDateChanged: saveExamDate,    // 保存はアプリ側
  languages: const [SettingsLanguage('ja', '日本語'), SettingsLanguage('en', 'English')],
  languageCode: currentCode,          // 2つ以上あるとき「言語」を出す
  onLanguageChanged: changeLanguage,  // 保存と文言の切り替えはアプリ側
  onTransfer: openTransferScreen,     // 渡すと「学習の引き継ぎ」を出す（画面はアプリ側）
  disclaimer: '本アプリは試験団体とは関係のない非公式のアプリです。',
)));
```

| 項目 | 出す条件 | 必要なもの |
|---|---|---|
| 受験日 | `onExamDateChanged` を渡す | — |
| 購入（広告非表示・プレミアム） | `showPurchase`（既定 true） | `entitlementServiceProvider` の override |
| 表示モード | `showTheme`（既定 true） | `loadSavedThemeMode()` と `appThemeMode`（下の「テーマ」参照） |
| 言語 | `languages` が2つ以上 | — |
| 片手・ながら学習 | `showHandsFree`（既定 true） | `handsFreeStoreProvider` の override |
| ご意見・不具合報告 | `showFeedback`（既定 true） | フィードバックの送信先（機能1） |
| 学習の引き継ぎ | `onTransfer` を渡す | — |
| このアプリについて | 常に出す（`disclaimer` があれば免責も） | — |

- アプリ固有の項目は `extraSections` に足す（`SettingsSection(title:, children:)` で見出しがそろう）
- `KitStringsScope` を `MaterialApp.builder` に置いていれば、設定画面も中の部品（購入欄・受験日）も同じ言語になる。置かない場合は `strings:` を渡す

## アプリ内レビューを頼むタイミング（`ReviewPromptService`）

良い体験の直後にだけ、頼みすぎないようにレビューを頼む。ストアのレビュー画面の実処理（`in_app_review` など）は、アプリが `ReviewBackend` として渡す（キットはプラグインに依存しない）。

```dart
// 1. アプリ側で ReviewBackend を実装して渡す
class MyReviewBackend implements ReviewBackend {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();
  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

ProviderScope(overrides: [
  reviewPromptServiceProvider.overrideWithValue(ReviewPromptService(
    store: SharedPreferencesReviewStore('boki3'),
    backend: MyReviewBackend(),
  )),
])

// 2. 起動時に load（初回起動の日付を記録する）
await ref.read(reviewPromptServiceProvider).load();

// 3. 良い体験（合格・自己ベスト・連続学習など）のたびに記録し、その直後に確認ダイアログを出す
final review = ref.read(reviewPromptServiceProvider);
await review.recordPositiveMoment();
await showReviewPrePrompt(context, review, onNegative: () => openFeedback(context));
```

- 既定の条件（`ReviewPromptRules`）: 初回起動から7日／良い体験3回／前回から120日／生涯3回まで／「いいえ」と答えた後は90日。条件を満たさなければ `showReviewPrePrompt` は何も出さない
- 「いいえ」ではレビューを頼まず、`onNegative` でフィードバックへ案内するのが定石（不満の声をストアのレビューに書かせない）
- 不具合の直後や学習の途中では呼ばない。頼んだ結果（星の数）はアプリ側からは分からない（OS の仕様）
- OS 側にも回数の制限がある（頼んでも画面が出ないことがある）。キットの上限は、それよりも控えめにしてある

## アクセシビリティの自動検査

`test/accessibility_test.dart` が、主要な共通UI部品を機械的に検査する: 文字200%・幅320dpでもはみ出さない／タップ領域が Android 48dp・iOS 44pt 以上／タップできるものに読み上げラベルがある／文字のコントラスト。言語（ja/en）と明暗の組み合わせすべてで行う。

新しい部品を足したら、テスト内の `_catalog` に1行足す。Flutter の検査は画面の端に接した部品を検査から外すので、部品は `_body`（周りに余白つき）に置くこと（置き方を間違えても、悪い部品を検知できているかの確認テストが落ちて気づける）。

## うかラボ専用の UI は `ukalab_core` にあります

v1.0.0 から、うかラボ専用の部品はこのパッケージから外れ、[ukalab_core](https://github.com/zka32101/ukalab_core)（`import 'package:ukalab_core/ui.dart';`）に移りました。このパッケージは**全アプリ共通のもの**だけを持ちます。

| 移った先（ukalab_core） | 中身 |
|---|---|
| 推し（マスコット） | `mascot/`（キャラクター・部屋・小物・推しカード・口調別セリフ） |
| 衣装・着せ替え・共有カード | `outfit/`（`WardrobeScreen`・`OutfitService`・合格報告・模試の記録） |
| 学習コイン・学習の引き継ぎ | `coin/`・`transfer/` |
| テーマ（資格ごとの色） | `UkalabTheme`・`UkalabPalette` |
| 学習ラボ系の部品 | 機械学習ラボ・畳み込み・NN 組み立て・注意の可視化・AI 動向・手法の選び方・評価指標・ストーリー・境界・失敗ギャラリー・予測実行・ルート・教えるマスコット |
| 下部タブ `UkalabShell`・準備完了カード・コイン内訳 | `ui_kit/` |

移した部品の使い方は ukalab_core の `docs/ui.md` を参照。旧コードは、このパッケージの `v0.30.0` のタグに残っています。

`KitStringsScope` から `mascotLines` を外しました（推しのセリフは ukalab_core の `UkalabScope` で渡します）。

`KitStrings` には、`ukalab_core` の UI が読む文言（コイン・着せ替え・推し・共有カード・下部タブなど、約50項目）が残っています。`ukalab_core` が `KitStrings.of(context)` 経由で使うため、**消すと `ukalab_core` が動かなくなります**。これらをうかラボ側へ移すかは、別途判断します（今は、キットに置いたまま）。

## 設計方針

- `cross_promo_kit` と同じく、依存は機能ごとに最小限に絞ります。
- 例外として権利管理は `purchases_flutter`、広告ゲートは `google_mobile_ads` に依存します（広めのレンジ指定）。
- Firebase は `cloud_firestore` だけに依存します（全国平均点の匿名集計 `FirebaseExamStatsService` と、
  コイン台帳の同期 `FirebaseCoinRemote`）。`firebase_auth` 等には依存せず、uid などは各アプリが渡します。
  それ以外の実データの送受信は各アプリ側がコールバックとして注入する設計です
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

### リリース（タグ）

`pubspec.yaml` の `version` を上げた変更が `main` に入ると、`vX.Y.Z` のタグが**自動で付く**（`.github/workflows/release-tag.yml`）。手順は、PR で `version` と `CHANGELOG.md` を更新してマージするだけ。

- 既にあるタグは動かさない（タグは不変）。`version` が `X.Y.Z` 以外（`+N` 付きなど）だとジョブが失敗する
- 複数の PR が同じ番号を取らないよう、PR の CI（`version-check`、`tools/check_version.sh`）が次を検査する: CHANGELOG に同じバージョンの見出しが無い／CHANGELOG の先頭が `pubspec.yaml` の `version` と一致する／`lib/` を変える PR は、まだタグのない `version` にしている（ほかの PR が先に同じ番号でマージされたら、`main` を取り込んで番号を上げ直す）
- 付け忘れ・過去分は、手動の `create-tag.yml`（Actions の Run workflow。タグ名とコミット SHA を入力）か、`tools/release_tag.sh [--dry-run] [コミット]` で付ける

## 多言語化（日本語・英語）

`KitStringsScope` で囲むと、キット内蔵ウィジェットの既定文言が切り替わる。囲まなければ日本語のまま（端末の言語には自動で従わない）。引数で渡した文言が常に優先。

```dart
KitStringsScope(strings: KitStrings.forLocale(Locale('en')), child: app)
```

**`MaterialApp.builder` など Navigator より上に置く**と、積まれた画面（`FeedbackFormPage` など）やダイアログにも届く（`home` の内側に置くと届かない）。画面・ダイアログは `strings:` を直接渡してもよい。

対応済み: 画面に出るウィジェットはほぼすべて（結果・コイン・フィードバック・合格報告・着替え・推し・マスコットのセリフ・ラボ系・選択肢・解説・下部タブ・片手モードの読み上げボタンなど）。共有カード（ブランド名・日付表記を含む。`PassShareCard(strings:)`）も対応。未対応（日本語のまま）: 衣装名・資格名などカタログのデータ。

### 言語を足す（中国語・韓国語など）

文言は3つの束に分かれている。どれも `copyWith` で一部だけ差し替えられるので、英語を土台に訳していくのが早い（項目を足したときの訳し忘れは、土台の英語のまま出る）。

| 束 | 内容 |
|---|---|
| `KitStrings` | 画面の文言（結果・コイン・フィードバック・着替え・共有カードなど） |
| `LabStrings` | ラボ系ウィジェット（機械学習ラボ・用語マップ・ストーリーなど） |
| 推しのセリフ | `Map<MascotTone, MascotLines>`（口調ごとのセリフ集） |

```dart
final zh = KitStrings.en.copyWith(languageCode: 'zh', coinTotal: '合计' /* … */);
final zhLabs = LabStrings.en.copyWith(progressDefault: '进度' /* … */);

KitStringsScope(
  strings: KitStrings.forLocale(locale, supported: {'zh': zh}), // 無い言語は ja（en は英語）
  labs: zhLabs,                                                  // 省略時は ja/en の既定
  mascotLines: {MascotTone.gentle: MascotLines({ /* … */ })},    // 省略時は ja/en の既定
  child: app,
)
```

- `languageCode` は必ず自分の言語にする（`en` 以外の言語で `labs` / `mascotLines` を渡さないと、それらは日本語になる）
- 推しのセリフは [`findForbiddenExpressions`](lib/mascot/mascot_lines.dart) の検査（責めない・煽らない）を、アプリ側のテストでも通すこと

### 内蔵の言語

画面の文言（`KitStrings`）は、ja・en・簡体字(`zh`)・繁体字(`zh-Hant`)・韓国語(`ko`) を内蔵している。`KitStrings.forLocale(locale)` が選ぶ（`zh_TW`・`zh_HK`・`zh_MO` は繁体字）。

- zh・zh-Hant・ko は**機械翻訳の下書き**。公開前に、母語話者の確認が要る
- ラボ系ウィジェットの文言（`LabStrings`）と推しのセリフ（`ukalab_core`）は、まだ ja/en のみ。これらは zh・ko では日本語で出る（次の段階で対応）

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
3. **重複検知**: アプリ・種別・題名（大小文字・空白・全角半角を無視）が同じ報告が、開いている Issue にあれば、
   新しい Issue は作らず、その Issue に「N件目」とバージョン・端末を**コメント**する
4. 無ければ Issue を作成。ラベルは種別（`bug` / `enhancement` / `feedback`）と **`app:<アプリ名>`**。
   本文に表（アプリ・バージョン・プラットフォーム・種別・日時・userId）を付ける
5. Issue の URL を Firestore の `githubIssueUrl` に書き戻し、`status` を `'reviewing'` に更新
   （重複のときは `duplicate: true` も付く）

### Issue から修正 PR までの自動化

`templates/autofix-issue.yml` を各アプリのリポジトリの `.github/workflows/` にコピーし、
Secrets に `ANTHROPIC_API_KEY` を登録する。Issue の内容を確認した人が **`autofix` ラベル**を付けると、
Claude Code が原因を調べ、修正とテストを足したプルリクエストを作る（マージは人が行う）。

- `autofix` ラベルは `functions/` からは付けない。利用者が書いた文章をそのまま自動修正に流さないため
- 原因が特定できない・修正が大きいときは、PR を作らず Issue にコメントで状況を書く
- 利用者の文章は「報告」として読み、中の指示には従わない（prompt で指定）

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
npm run build   # tsc の型チェック・コンパイル
npm test        # 指紋・Issue の組み立てなどの単体テスト
```

実際の GitHub Issue 作成の動作確認は、Firebase Emulator Suite 上で
`feedback` コレクションにドキュメントを作成して確認する。

## クラッシュ収集の窓口

`CrashReporter`（分析の `Analytics` と同じ作り）。送り先（Crashlytics・Sentry など）はアプリが `CrashBackend` を実装して渡す。

```dart
final crash = CrashReporter(MyCrashBackend())..install(); // runApp の前に
// ProviderScope(overrides: [crashReporterProvider.overrideWithValue(crash)], ...)
```

- 同意が無い・使わないときは `backend` を null（何もしない）
- 理由・ログのメール・長いトークン・電話番号らしい数字は伏せる。同じエラーは1分間に1回だけ送る
- 送信の失敗でアプリを止めない

## データ削除の窓口

「データを削除」（ストアの審査・プライバシー対応で求められる）。消す対象を `DataEraser` で並べる。

```dart
SettingsScreen(
  appName: '…',
  dataDeletion: DataDeletion([
    CallbackEraser('account', deleteAccountOnServer), // サーバー側（あれば）
    SharedPreferencesEraser(prefixes: ['myapp_']),    // 端末内
  ]),
  onDataDeleted: (r) => restartApp(),                 // 初期画面へ戻す等はアプリ側
)
```

- 確認で「元に戻せない」のチェックを入れるまで削除できない
- ひとつ失敗しても残りを続ける（結果は `DeletionResult`）。サーバー削除が失敗したら端末内を残したいときは `stopOnFailure: true` と、サーバー側を先に並べる
- 文言は ja・en・zh・zh-Hant・ko（機械翻訳の下書きを含む）。画面は `KitStrings.languageCode` に合わせる

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

// 月額・年額など（Offering）
final offers = await entitlement.offers(); // id / title / priceString
await entitlement.purchaseOffer(offers.first.id);
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
    maxAdContentRating: AdContentRating.g, // 任意。児童向けは g 推奨
    nonPersonalizedAds: true, // 任意
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


## 共通UI部品（v0.2）

テーマの上で使う。色は `Theme` から取るので直書きしない。文言は引数で差し替えられる（既定は日本語）。

```dart
QuestionCard(index: 3, total: 10, text: '…', child: Column(children: [
  ChoiceTile(label: 'A', text: '…', state: ChoiceState.correct),   // ✓＋「正解」
  ChoiceTile(label: 'B', text: '…', state: ChoiceState.incorrect), // ✕＋「不正解」
]));
ExplanationPanel(body: '…', sourceRef: '道路交通法第34条', checkedAt: '2026-10-02');
```

- 正誤は色だけにせず、✓／✕のアイコンと文言を必ず併記する
- `ProgressRing` は文字拡大でも収まるよう縮める。値の範囲外・NaN は丸める

### 用語カード（v0.3、決定50「専門用語の解説（全アプリ共通）」）

問題文・解説文中の専門用語に下線をつけ、タップでボトムシートに用語カードを開く。データ（`Term`・配信前検証）は `ukalab_core` 側。

```dart
TappableTermText(
  text: '過学習はニューラルネットワークでも起こる。',
  terms: const [TermReference(termId: 't1', matchText: '過学習')],
  onTermTap: (termId) => showTermCard(
    context,
    term: '過学習',
    headline: '練習問題は得意だが、新しい問題には弱くなること',
    definition: '学習データに対して過剰に適合し、未知のデータへの汎化性能が低下する現象。',
    analogy: '過去問だけを丸暗記して、少し出題形式が変わると解けなくなる状態に近い。',
    relatedTerms: const [RelatedTermRef(termId: 't2', label: '正則化')],
    onRelatedTermTap: (nextId) {
      // 関連用語のタップで、その用語の showTermCard を呼び直して遷移する
    },
  ),
);
```

- 下線は色だけに頼らない（`decorationThickness: 2`）
- 関連用語・関連問題はコールバックが渡されなければ非活性


## 片手・ながら学習モード

通勤中などの片手操作と、耳で聞く学習のための共通部品。モードを有効にすると、画面は**大きなボタンを下部に並べ**、問題文・選択肢・解説を**端末標準の音声合成**で読み上げる。

```dart
// 設定（ホーム／設定画面のスイッチ）
ProviderScope(overrides: [
  handsFreeStoreProvider.overrideWithValue(SharedPreferencesHandsFreeStore('g_kentei')),
]);
await ref.read(handsFreeProvider.notifier).load();          // 起動時
await ref.read(handsFreeProvider.notifier).setEnabled(true); // スイッチ

// 読み上げ。音声合成は端末標準（flutter_tts など）をアプリが SpeechBackend として実装して渡す
final speaker = HandsFreeSpeaker(backend: myTts, settings: () => ref.read(handsFreeProvider));
await speaker.readQuestion(q.prompt, q.choices); // モードが有効で「問題を読み上げる」がオンのときだけ読む
await speaker.readExplanation(q.explanation);

// 画面: 問題文は上、選択肢は下に寄せる
HandsFreeQuestionLayout(
  question: QuestionCard(...),
  trailing: ReadAloudButton(onPressed: () => speaker.speakNow(text)), // ボタンはモードに関わらず読む
  choices: [for (...) HandsFreeChoiceTile(label: 'ア', text: c, state: state, onTap: onTap)],
)
```

- ボタンは高さ 72pt 以上。✓／✕のアイコンと文言も出す（色だけに頼らない）
- 読み上げは失敗しても例外を出さず、学習を止めない（`false` を返す）。端末の音声合成が使えない場合も同じ
- 設定: 有効／問題を読む／解説を読む／読み上げの速さ（0.5〜1.5）。保存先は `SharedPreferencesHandsFreeStore(appId)`
- 数式・図の読み上げは対象外（問題文・解説の文字だけ）。読ませたくない部分は、アプリ側で読み上げ用の文を別に渡す

## 全国平均点・偏差値の匿名集計（決定32）

`ExamStatsService` は模擬試験結果を匿名で集計し、全国平均点・偏差値を結果画面に表示するための抽象。

```dart
await ref.read(examStatsServiceProvider).submitResult(ExamStatsSubmission(
  certId: 'g_kentei',
  examVersion: exam.version,
  score: correct,
  totalQuestions: total,
));
final summary = await ref.read(examStatsServiceProvider)
    .fetchSummary(certId: 'g_kentei', examVersion: exam.version);
// StatsCompareWidget(summary: summary, myScore: correct) を結果画面に出す
```

- Firestore には `exam_stats/{certId}_{examVersion}` に件数・合計・平方和の3フィールドだけを持つ（個々の提出は保存しない）。平均・標準偏差はこの3値から導出する（Cloud Functions 不要）
- `examVersion` は出題配分（`ExamConfig` の章別問題数）が変わるたびに上げる。配分が違う回と混ぜて集計しないため
- サンプルが10件未満、または分散が0の場合は `deviationScoreFor` が null を返す（`StatsCompareWidget` は偏差値欄を出さない）
- `FirebaseExamStatsService` を使うには `firebase_core` の初期化（`google-services.json` / `GoogleService-Info.plist` の配置）が必要。実際の Firebase プロジェクトを用意するまでは `FakeExamStatsService` で動かす
- Firestore ルールのテンプレートは `firestore.rules.template`。書き込みは増分の3フィールドのみに制限し、**Firebase Console の App Check を enforce にすること**（App Check 自体はコードではなくプロジェクト設定）


## 用語マップ・AI系譜図（決定41、画期的な機能9）

`TermMapWidget` は、関連用語でつながる地図（用語マップ）と、時代区分に沿ったタイムライン（系譜図）の両方を1つのウィジェットで出す。

```dart
TermMapWidget(
  nodes: [
    for (final t in terms)
      TermMapNodeSpec(
        termId: t.termId,
        label: t.term,
        era: t.era, // ukalab_core の Term.era。null なら用語マップ側のみ
        relatedTermIds: t.relatedTermIds,
        mastery: masteryOf(t.termId), // アプリ側が学習ログから判定
      ),
  ],
  eraOrder: const {
    'boom1': '第1次AIブーム',
    'winter1': '第1次AIの冬',
    'boom2': '第2次AIブーム',
    'winter2': '第2次AIの冬',
    'deep_learning': '深層学習の時代',
    'generative_ai': '生成AIの時代',
  },
  onNodeTap: (termId) => showTermCard(context, ...),
)
```

- `era` を持つ用語は `eraOrder` の順でタイムライン表示、持たない用語は関連（`relatedTermIds`）でつながる円形配置のネットワーク表示になる
- `mastery`（`TermMastery.none` / `.weak` / `.mastered`）は色だけに頼らずアイコンでも区別する（weak: `!`、mastered: `✓`）
- タイムライン・用語マップともタップで `onNodeTap(termId)` を呼ぶだけで、用語カードを開く処理はアプリ側（`showTermCard`）に委ねる


## 表示モード・連続学習日数の永続化（v0.10.0）

各アプリが独自に実装しがちな、`SharedPreferences` だけで完結する軽量な永続化を2つ追加（元は
`ukalab-boki3`（簿記3級アプリ）が個別実装していたもので、共通基盤に既にあった `StreakBadge` と
気づかず重複実装していたため、ここに吸収した）。

- `lib/theme/theme_mode_store.dart`：`appThemeMode`（`ValueNotifier<ThemeMode>`）・
  `loadSavedThemeMode()`・`setThemeMode(mode)`。`MaterialApp` の `themeMode` にリッスンさせるだけで、
  設定画面からライト/ダーク/端末設定に従うを切り替えられる。
- `lib/progress/streak_store.dart`：`recordStudyToday({now})`・`loadCurrentStreak({now})`。
  演習などを1件記録するたびに呼ぶと、前日から続けていれば+1、2日以上空けば1から数え直す連続学習日数を
  `SharedPreferences` に保存する。表示は既存の `StreakBadge`（`ui_kit/streak_badge.dart`）と組み合わせる。

どちらも保存キーをパッケージ非依存の固定文字列にしており、アプリごとに個別の名前空間指定は不要
（各アプリはOS側で独立したストレージサンドボックスを持つため、キーの衝突は起きない）。

## 強制アップデート・お知らせ

配信側（Firebase Remote Config など）の値を `UpdateBackend` で返せば、起動時に1行で確認できる。キットは Remote Config に依存しない。

```dart
await promptForUpdate(
  context,
  backend: MyRemoteConfigUpdateBackend(), // UpdatePolicy(minVersion:, latestVersion:, storeUrl:, message:) を返す
  currentVersion: appVersion,
  openStore: (url) => launchUrl(Uri.parse(url ?? defaultStoreUrl)),
);
```

- `minVersion` 未満 → 閉じられない強制ダイアログ / `latestVersion` 未満 → 「あとで」できる案内
- 取得に失敗してもアプリは止めない（何も出さない）

## 分析イベント

イベント名をアプリ間でそろえ、個人情報の混入を防ぐ共通の窓口。送り先（Firebase Analytics など）はアプリが `AnalyticsBackend` で実装して渡す。

```dart
ProviderScope(overrides: [
  analyticsProvider.overrideWithValue(Analytics(MyFirebaseAnalyticsBackend())),
], child: ...);

ref.read(analyticsProvider).log(AnalyticsEvents.studyComplete, {'cert': 'it_passport', 'score': 80});
```

- 名前は英小文字・数字・`_`（40字以内）。違反は送らない
- `email`・`name`・`uid`・`token` などのキーは自動で落とす。文字列は100字、パラメータは25個まで
- 同意前など、送り先を渡さなければ何もしない。送信の失敗でアプリは止まらない

## 共通基盤のタグ更新を、アプリへ自動で PR にする

アプリは `ref: vX.Y.Z` でタグ固定のため、新しいタグが出ても自動では追従しない（放っておくと、古いまま取り残される）。
`templates/kit-update.yml` を各アプリの `.github/workflows/` にコピーすると、毎日タグを確かめ、新しいものがあれば PR を作る。

- 対象: `pubspec.yaml` の git 依存のうち、`github.com/zka32101/` のリポジトリで `ref` が `vX.Y.Z` のもの（`app_common_kit`・`ukalab_core`・`cross_promo_kit` など）
- 上げるだけ（下げない）。major が上がるときは PR に ⚠ が付く
- PR を作る前に、同じジョブの中で `flutter pub get`・`analyze`・`test` を走らせ、結果を本文に書く
- 設定: Settings → Actions → General →「Allow GitHub Actions to create and approve pull requests」をオンにする。アプリの CI も PR で動かしたいときは `KIT_UPDATE_TOKEN`（PAT）を Secrets に入れる
- 手動で試す: `python3 tools/kit_update/bump_kit_refs.py pubspec.yaml`

## 互換チェック（マージ前に、アプリが壊れないか確かめる）

`lib/`・`assets/`・`pubspec.yaml` を変える PR では、`compat` ワークフローが走る。使っている5つのアプリ（`ukalab_otsu4`・`ukalab_g_kentei`・`ukalab_boki`・`ukalab_seisei_ai_passport`・`ukalab_kanken`）の main に、この PR のコードを差し込み、`flutter pub get`・`analyze`（エラーのみ）・`test` を通す。アプリごとに結果が出るので、どのアプリが壊れるかが分かる。

- 題名が `feat!:` のような破壊的変更（`!:` を含む）は、アプリ側の移行が要るので飛ばす
- `ukalab_kanken` は、main のままでもテスト4件（`hands_free_wiring_test`）がローカルで失敗するため、テストは飛ばして解析のエラーだけを見る
- アプリを足したら、`.github/workflows/compat.yml` の matrix に1行足す

