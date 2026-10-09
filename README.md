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

### リリース（タグ）

`pubspec.yaml` の `version` を上げた変更が `main` に入ると、`vX.Y.Z` のタグが**自動で付く**（`.github/workflows/release-tag.yml`）。手順は、PR で `version` と `CHANGELOG.md` を更新してマージするだけ。

- 既にあるタグは動かさない（タグは不変）。`version` が `X.Y.Z` 以外（`+N` 付きなど）だとジョブが失敗する
- 付け忘れ・過去分は、手動の `create-tag.yml`（Actions の Run workflow。タグ名とコミット SHA を入力）か、`tools/release_tag.sh [--dry-run] [コミット]` で付ける

## 多言語化（日本語・英語）

`KitStringsScope` で囲むと、キット内蔵ウィジェットの既定文言が切り替わる。囲まなければ日本語のまま（端末の言語には自動で従わない）。引数で渡した文言が常に優先。

```dart
KitStringsScope(strings: KitStrings.forLocale(Locale('en')), child: app)
```

**`MaterialApp.builder` など Navigator より上に置く**と、積まれた画面（`FeedbackFormPage` など）やダイアログにも届く（`home` の内側に置くと届かない）。画面・ダイアログは `strings:` を直接渡してもよい。

対応済み: 画面に出るウィジェットはほぼすべて（結果・コイン・フィードバック・合格報告・着替え・推し・マスコットのセリフ・ラボ系・選択肢・解説・下部タブ・片手モードの読み上げボタンなど）。共有カード（ブランド名・日付表記を含む。`PassShareCard(strings:)`）も対応。未対応（日本語のまま）: 衣装名・資格名などカタログのデータ。


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
- 端末移行・同期: `CoinLedger.toJson()` を共通アカウントに保存し、`CoinService.mergeLedger` で統合（何度統合しても同じ）。サーバー側の保存は下の「共通アカウントで同期する」を参照
- 数値は暫定（学習コイン仕様 §2）。`CoinRules` を作り直して調整
- 網羅率や正答率の**到達判定**は呼び出し側（学習ログ）が行い、到達したらイベントを渡す

### 共通アカウントで同期する（Firestore）

端末移行・複数端末で、同じアカウントなら同じコインになる。台帳は追記専用で行ごとに ID があるため、何度同期しても二重にならない。

```dart
// 1. サインイン後（匿名でも可）に、保存先を作る。uid は Firebase Auth の uid。
final remote = FirebaseCoinRemote(uid: user.uid, examId: UkalabCert.bikeLicense.id);

// 2. 起動時と、購入の後に同期する。5分以内の再同期は自動でスキップ、失敗しても例外は出ない。
await ref.read(coinProvider.notifier).load();
await ref.read(coinProvider.notifier).syncWith(remote, minInterval: const Duration(minutes: 5));
// 購入後:  await notifier.purchase(id); await notifier.syncWith(remote);
```

- 保存先は `users/{uid}/exams/{examId}/coin/ledger`。共通ルール（`firebase/firestore.rules`）に含まれるため、**ルールの変更は不要**（本人だけが読み書きでき、examId は登録済みの資格だけ）
- 台帳は1ドキュメント（Firestore の1MB上限）。1行 約150バイトで 6,000行ほど。1日の獲得上限があるので通常は収まる
- 装備中の衣装は端末ごと（同期しない）
- 2台で同時に購入すると、統合後の残高が一時的にマイナスになりうる（購入は残高以内でしか記録しないが、オフラインの2台は互いを知らないため）。マイナスは次の獲得で戻る。必要ならアプリ側で表示を 0 に丸める
- Firestore 以外に置くなら `CoinRemote`（`readLedger`/`writeLedger`）を実装して渡す

### 学習の引き継ぎ（機種変更）

学習履歴・コイン・衣装を、共通アカウント（匿名 → Google/Apple リンクでも uid は変わらない）のサーバーへ保存し、新しい端末へ復元する。復元は**統合**で、端末内のデータを消さず、何度実行しても二重にならない。部品ごとに処理し、1つの失敗で他を止めない（例外は出さない）。

```dart
final transfer = LearningTransfer(
  remote: FirebaseTransferRemote(uid: user.uid, examId: UkalabCert.gKentei.id),
  sources: [
    CoinTransferSource(coinService),       // コイン台帳（id が同じ行は一度だけ）
    OutfitTransferSource(outfitService),   // 合格・準備完了・着ている衣装
    FunctionTransferSource(                // 学習履歴などは、アプリが中身を渡す
      partId: 'progress',
      onExport: () async => [for (final r in await store.loadRecords()) r.toJson()],
      onImport: (remote) async { /* remote(List) を端末内の記録へ統合。冪等にする */ },
    ),
  ],
);

await transfer.backup();                  // 旧端末: 起動時・学習後などに保存
final result = await transfer.restore();  // 新端末: ログイン直後に復元
// result.status: success / partial / failed。result.failed は後でやり直せる
// result.nothingToRestore: バックアップが一度も無い（新規利用者）
```

- 保存先は `users/{uid}/exams/{examId}/transfer/{partId}`（部品ごとに1ドキュメント）。共通ルールに含まれるため、**ルールの変更は不要**
- 1部品は Firestore の1MB上限まで。学習履歴が大きいアプリは、部品を分けるか、期間で切り分けて渡す
- `partId` は一意にする（英数字とアンダースコア）。Firestore 以外に置くなら `TransferRemote`（`readPart`/`writePart`）を実装して渡す
- 学習履歴（`yourwish_kentei` の `ProgressRecord`）の統合は、`qid` と `at` が同じ記録を重複させない形でアプリ側が実装する


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


## 手法の選び方（事例仕分け、画期的な機能6）

`MethodChoiceWidget` は、事例の説明を読んで適切な手法・モデル・評価指標を選び、正解すると理由を見る。

```dart
MethodChoiceWidget(
  scenario: MethodChoiceScenarioSpec(
    title: '顧客の離脱予測',
    caseDescription: '顧客の年齢・購入履歴から、将来の離脱(はい/いいえ)を予測したい。',
    options: const [
      FailureChoiceSpec(optionId: 'classification', text: '分類（教師あり学習）', isCorrect: true),
      FailureChoiceSpec(optionId: 'clustering', text: 'クラスタリング（教師なし学習）', isCorrect: false),
    ],
    explanation: '正解・不正解のラベル付きデータから学習するため、分類(教師あり学習)が適切。',
  ),
)
```

- 選択肢は `FailureChoiceSpec`（`failure_gallery.dart`）を再利用する。`ConfusionMatrixLabWidget` の選択パートと同じ構造で、混同行列の操作だけがない最小版


## 機械学習ラボ（画期的な機能1）

`MlLabWidget` は、2クラスのデータ点をk近傍法・決定木・線形分類の3手法で分類し、決定境界（背景の塗り分け）とハイパーパラメータによる過学習・未学習の変化を見せる。分類の計算（kNN・CART風の決定木・正則化付きロジスティック回帰）はこのウィジェット内で行う。

```dart
MlLabWidget(
  title: '線形分離',
  description: '2つのかたまりに分かれた点です。',
  points: const [
    MlLabPointSpec(x: 1, y: 1, label: 0),
    MlLabPointSpec(x: 8, y: 8, label: 1),
    // ...
  ],
)
```

- 座標は0〜10の範囲を想定（グリッド24×24で決定境界を塗り分ける）
- ハイパーパラメータ: k近傍法は`k`（1〜15）、決定木は`深さ`（1〜6）、線形分類は`正則化`（0〜2.0）
- クラスは色だけに頼らず形も変える（クラス0は丸、クラス1は三角）


## 今月のAI動向（画期的な機能10、決定41）

`AiNewsCard` は、ホームに3〜5件のAI動向を表示する。毎週の収集・運営者確認・月次の差分更新はアプリの外（人・定期タスク）で行い、このウィジェットは配信済みのデータを表示するだけ。

```dart
AiNewsCard(
  items: [
    AiNewsItemSpec(
      summary: '生成AIの新しい基盤モデルが発表された。',
      sourceUrl: 'https://example.com/news/1',
      sourceDate: DateTime(2026, 9, 1),
      syllabusTag: '2 人工知能をめぐる動向',
      asOfDate: DateTime(2026, 10, 1),
      isExamRelevant: true,
    ),
    // ...
  ],
)
```


## 画像認識の中身を見る（画期的な機能4）

`ConvLabWidget` は、手書き風の数字・図形（グレースケールの格子）に畳み込みフィルタ（縦/横エッジ検出・ぼかし・シャープ化）を当て、入力画像→特徴マップ→プーリング後（2x2 max pooling）の3段階を並べて表示する。畳み込み・プーリングの計算はこのウィジェット内で行う。

```dart
ConvLabWidget(
  image: ConvLabImageSpec(
    title: '手書き風の「1」',
    description: '縦棒だけの画像。',
    grid: [
      [0, 0, 1, 0, 0, 0, 0, 0],
      // ... 8x8以上のグレースケール値(0.0〜1.0)
    ],
  ),
)
```

- フィルタは`ConvFilter`（`verticalEdge` / `horizontalEdge` / `blur` / `sharpen`）の4種類で固定
- 入力画像はそのままの値をグレースケール表示、特徴マップ・プーリング後は最小〜最大を0.0〜1.0に正規化して表示（負の値も見えるようにする）

- 項目が空なら何も表示しない
- 「◯年◯月時点」はカード全体の見出しに1回だけ表示する（各項目の`asOfDate`の最大値）
- 「試験に出そう」印は色だけに頼らずアイコン（旗）とバッジ文言で示す
- 出典URLは`SelectableText`で表示するだけで、タップでの外部遷移は行わない（`url_launcher`非依存）


## Transformerの注意の可視化（画期的な機能5）

`AttentionVizWidget` は、短い文の単語（トークン）同士の注意（Attention）の強さを、線の太さ・濃さで見せる。注目する単語（クエリ）をチップで選ぶと、他の単語への注意の強さに応じて線が変化する。値は教育用に用意した固定データで、実際のモデルの出力ではないことを画面上に明記する。

```dart
AttentionVizWidget(
  scenario: AttentionVizSpec(
    title: '誰が何を食べた？',
    description: '「食べた」がどの単語に注目しているか見てみましょう。',
    tokens: ['猫', 'が', '魚', 'を', '食べた'],
    attention: [
      [0.6, 0.1, 0.1, 0.05, 0.15],
      // ... 各行の合計がおよそ1.0になる注意の強さ(0.0〜1.0)
    ],
  ),
)
```

- 色だけに頼らず、クエリ側は上向きの三角マーカー、最も注目されたキー側は星マーカーで示す
- 最も強く注目している単語とその割合(%)を文章でも表示する


## ニューラルネット組み立て（画期的な機能2）

`NnBuilderWidget` は、隠れ層の数・ユニット数・活性化関数・学習率を選び、2クラスのデータ点を分類する小さな全結合ニューラルネットを実際に学習させて、決定境界と学習曲線（訓練誤差）の変化を見せる。順伝播・誤差逆伝播法（バックプロパゲーション）による学習自体をこのウィジェット内で行う。

```dart
NnBuilderWidget(
  title: '2つのかたまりを分ける',
  description: '2つのかたまりに分かれた点です。',
  points: const [
    NnBuilderPointSpec(x: 1, y: 1, label: 0),
    NnBuilderPointSpec(x: 8, y: 8, label: 1),
    // ...
  ],
)
```

- 隠れ層は1層または2層、ユニット数は2〜8、活性化関数はシグモイド/ReLU/tanh、学習率は0.1〜3.0から選べる（出力層は常にシグモイド、二値分類）
- 座標は0〜10の範囲を想定（グリッド24×24で決定境界を塗り分ける）。クラスは色だけに頼らず形も変える（クラス0は丸、クラス1は三角）
- 学習曲線は固定400エポックのフルバッチ勾配降下法。乱数シードは固定し、同じ設定なら毎回同じ結果になる


## ストーリー型の共通エンジン（決定38）

`StoryModeWidget` は、複数資格で共用するストーリー型の体験（簿記3級の会社経営モード・乙4の現場の1日モード・G検定のAIプロジェクト経営モードなど）の章立て・選択・解説・振り返りを支える汎用エンジン。シナリオ・会社など具体的な内容は `StoryScenarioSpec` としてアプリ側が渡す。

```dart
StoryModeWidget(
  scenario: StoryScenarioSpec(
    title: 'AIプロジェクト経営モード',
    description: '架空の会社でAI導入を進めます。',
    chapters: const [
      StoryChapterSpec(
        situation: 'データ収集の段階。どちらの方法を選びますか?',
        choices: [
          StoryChoiceSpec(
            choiceId: 'license',
            text: '出典・ライセンスを確認して収集',
            isRecommended: true,
            feedback: '権利関係を確認してから使うのが基本。',
          ),
          // ...
        ],
      ),
      // ...
    ],
  ),
)
```

- 章を1つずつ進み、各章で選択肢を選ぶと、推奨の判断かどうかとその理由（解説）を表示する。最後の章まで進むと、章ごとの判断を振り返る
- 色だけに頼らず、推奨の判断には✓アイコン、そうでない判断には△アイコンを付ける
- 途中保存の仕組みは持たない（現状は短い章数の体験を想定）。長い章数のシナリオ（簿記3級の会社経営モードなど）向けの途中保存は、必要になった時点で追加する

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
