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


## テーマ（v0.2）

分野（と資格）を渡すだけで、共通デザイン仕様 v0.4 の ThemeData が作れる。色の直書きはしない。

```dart
MaterialApp(
  theme: UkalabTheme.light(field: UkalabField.ai, cert: UkalabCert.gKentei),
  darkTheme: UkalabTheme.dark(field: UkalabField.ai, cert: UkalabCert.gKentei),
)
```

- 資格を省くと分野色になる。`cert.field` と `field` が合わないと assert で失敗する
- 色のトークンは `UkalabPalette.resolve(...)`、コントラスト比は `contrastRatio(a, b)`
- **success（ライト #1E8E3E）は背景の上で 4.0〜4.2:1 で、文字としては AA に届かない**。✓アイコンなど図形として使い、正誤は必ず✓／✕と文言を併記する


## 共通UI部品（v0.2）

テーマ（`UkalabTheme`）の上で使う。色は `Theme` から取るので直書きしない。文言は引数で差し替えられる（既定は日本語）。

```dart
QuestionCard(index: 3, total: 10, text: '…', child: Column(children: [
  ChoiceTile(label: 'A', text: '…', state: ChoiceState.correct),   // ✓＋「正解」
  ChoiceTile(label: 'B', text: '…', state: ChoiceState.incorrect), // ✕＋「不正解」
]));
ExplanationPanel(body: '…', sourceRef: '道路交通法第34条', checkedAt: '2026-10-02');
UkalabShell(pages: [home, learn, mock, record, settings]); // ホーム／学ぶ／模擬／記録／設定
```

- 正誤は色だけにせず、✓／✕のアイコンと文言を必ず併記する
- `ProgressRing` は文字拡大でも収まるよう縮める。値の範囲外・NaN は丸める

### 用語カード（v0.3、決定50「専門用語の解説（全アプリ共通）」）

問題文・解説文中の専門用語に下線をつけ、タップでボトムシートに用語カードを開く。データ（`Term`・配信前検証）は `yourwish_kentei` 側。

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


## 学習コイン（v0.2）

学習の成長でのみ獲得できる。使い道は見た目だけ。財布は**アプリごと**（`SharedPreferencesCoinStore(appId)`）。

```dart
final coin = CoinService(store: SharedPreferencesCoinStore('bike'), shop: items);
await coin.load();
final g = await coin.grant(CoinEvent.newQuestion('q123')); // 付与したら CoinGrant、重複・上限なら null
await coin.purchase('hat'); // purchased / insufficient / alreadyOwned / unknownItem
```

- 重複防止: 同じ問題・同じ段階・同じ資格は二度付与されない。1日の上限（新しい問題30コイン、復習20コイン、自己ベスト3回）あり
- 残高は台帳の合計。購入は残高以内でしか記録しないので負にならない
- 端末移行・同期: `CoinLedger.toJson()` を共通アカウントに保存し、`CoinService.mergeLedger` で統合（何度統合しても同じ）。**サーバー側の保存は未実装**（アプリ側の Firestore などに置く）
- 数値は暫定（学習コイン仕様 §2）。`CoinRules` を作り直して調整
- 網羅率や正答率の**到達判定**は呼び出し側（学習ログ）が行い、到達したらイベントを渡す


## 推し（v0.2）

```dart
final model = MasteryModel.standard;
final stage = model.stageOf(MasteryInput(coverage: 0.3, accuracy: 0.8)); // Lv2
final day = MascotDayState(studiedToday: true, examDate: examDate);
MascotWidget(
  stage: stage,
  expression: day.expression,          // 学習した日はよろこび。責める表情はない
  examPhase: day.examPhase(DateTime.now()),
  line: MascotLines.gentle.pick(MascotSituation.studied, seed: dayOfYear),
);
```

- 標準キャラはコード描画で画像不要。AI 画像のパックは `CharacterPack(imageBuilder: ...)` を渡す（画像がまだ取れないときは null を返せば標準の描画に戻る）
- 習得度の式と段階の境目は暫定（網羅率×正答率、0.2／0.4／0.6／0.8）。`MasteryModel` の引数で差し替える
- セリフは `findForbiddenExpressions` で検査する。追加するときは test/mascot_test.dart の検査に通すこと
- 設定の「推しを小さく／非表示」は `MascotDisplay`、「動きを減らす」は端末設定に従う


## 衣装・資格連動（v0.2）

| 衣装 | 入手 | 呼び出し |
|---|---|---|
| 通常（資格別の小物） | コインで買う（300） | `CoinService.purchase(OutfitCatalog.idOf(cert, OutfitKind.regular))` |
| 合格記念 | 合格報告で「合格」を選んだ場合のみ（無料） | `OutfitService.reportPassed(cert)`（コインの `CoinEvent.passReport` は別に付与） |
| 試験日の装い | 試験日を設定した人だけ（無料） | `examPhase` を渡す |
| 準備完了 | 最短ルートの目標達成（無料） | `OutfitService.markReady(cert)` |

- 衣装は分野の小物と資格のシンボルだけで表す。試験団体のロゴ・制服・公式の意匠は使わない
- 共有カードは `PassShareCard(data: ShareCardData(...))`。名前・メール・IDの欄は作らない。画像化は `RepaintBoundary` に key を付けて `captureShareCard(key)`


## アイコン生成（tools/icon_gen）

共通テンプレート（上段「うかラボ」／中央にシンボル／下部に試験名。組織ロゴ・✓バッジなし）で、データから量産する。

```bash
pip install -r tools/icon_gen/requirements.txt
python tools/icon_gen/icon_gen.py --spec tools/icon_gen/specs/sample.json --out build/icons
python tools/icon_gen/check_icons.py --spec tools/icon_gen/specs/sample.json --out build/icons
```

- 定義（JSON）: `{"id": 資格ID, "short": 試験名の短縮, "symbol": symbols/ のファイル名}`。資格IDは `UkalabCert.id`
- シンボルは白一色の SVG（viewBox `-50 -50 100 100`）を `tools/icon_gen/symbols/` に置く。中抜きの色が必要なら `__BG__`（背景色に置換）
- 出力: `<id>_1024.png`、`<id>_fg.png`／`<id>_bg.png`（Android adaptive。前景は中央66%以内）、`<id>_small_1024.png`（最小サイズ用）
- 日本語の太字フォントが必要（Windows は游ゴシック、CI は fonts-noto-cjk）。`--font` で指定もできる
- AI 画像は使わない。試験団体のロゴ・「公式」「認定」の文字は入れない
- シンボルの最終デザインは未決（サンプルは仮）
- 実際のアプリ用の定義は `tools/icon_gen/specs/ukalab_apps.json`（今は `bike_license` のみ。シンボル `motorcycle` は仮のデザイン）。アプリのアイコンを更新するときは、これで生成して `<id>_1024.png`・`<id>_fg.png`・`<id>_bg.png` を使う


## 全国平均点・偏差値の匿名集計（決定32）

`ExamStatsService` は模擬試験結果を匿名で集計し、全国平均点・偏差値を結果画面に表示するための抽象。

```dart
await ref.read(examStatsServiceProvider).submitResult(ExamStatsSubmission(
  certId: UkalabCert.gKentei.id,
  examVersion: exam.version,
  score: correct,
  totalQuestions: total,
));
final summary = await ref.read(examStatsServiceProvider)
    .fetchSummary(certId: UkalabCert.gKentei.id, examVersion: exam.version);
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
        era: t.era, // yourwish_kentei の Term.era。null なら用語マップ側のみ
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


## 評価指標ラボ（画期的な機能3）

`ConfusionMatrixLabWidget` は、混同行列（TP/FP/FN/TN）をスライダーで自由に動かすと正解率・適合率・再現率・F値が連動する様子を見せ、続けて「偽陽性と偽陰性のどちらが重いか」の場面問題につなげる。

```dart
ConfusionMatrixLabWidget(
  scenario: ConfusionMatrixScenarioSpec(
    title: 'がん検診',
    description: '見逃し(偽陰性)と誤検知(偽陽性)、どちらが重いか。',
    initialTp: 40, initialFp: 10, initialFn: 10, initialTn: 40,
    options: const [
      FailureChoiceSpec(optionId: 'recall', text: '再現率を優先する', isCorrect: true),
      FailureChoiceSpec(optionId: 'precision', text: '適合率を優先する', isCorrect: false),
    ],
    explanation: '病気を見逃す(偽陰性)方が重いため、再現率を優先する。',
  ),
)
```

- スライダーの可動範囲は初期値の合計と100の大きい方。初期値がそれを超えるデータでも壊れない
- 選択肢は `FailureChoiceSpec`（`failure_gallery.dart`）を再利用する。正解を選ぶまで `ChoiceChip` は選択状態に戻らず、再挑戦できる
