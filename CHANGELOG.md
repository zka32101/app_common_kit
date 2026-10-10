# Changelog

破壊的変更は major を上げ、移行手順を記載する。タグは不変（付け替えない）。

## [0.30.0]

### 追加
- フィードバックの Issue 自動化を強化（`functions/`）: 同じ内容の報告は既存 Issue にコメントして重複を防ぐ（指紋）、`app:<アプリ名>` ラベル、メタ情報の表、本文の長さ制限。単体テストを追加し CI で実行
- `templates/autofix-issue.yml`: Issue に `autofix` ラベルを付けると Claude Code が修正 PR を作る GitHub Actions のテンプレート

## [0.29.0]

### 追加
- 分析イベントの共通窓口: `AnalyticsBackend`（Firebase Analytics 等をアプリ側で実装）、`FakeAnalyticsBackend`、共通イベント名 `AnalyticsEvents`、`Analytics`（イベント名・パラメータの検査、個人情報らしいキーの除外、100字切り詰め、25個上限、送信例外の握りつぶし）、`analyticsProvider`

## [0.28.0]

### 追加
- 強制アップデート・お知らせ: `UpdatePolicy`（minVersion / latestVersion / storeUrl / message）、`UpdateBackend`（Remote Config 等をアプリ側で実装して渡す）、`FakeUpdateBackend`、`compareVersions` / `decideUpdate` / `checkForUpdate`、`promptForUpdate`（強制は閉じられない・任意は「あとで」可）。取得失敗は無視してアプリを止めない。ja/en 文言つき

## [0.27.0] - 2026-10-10

アプリ内レビューを頼むタイミングの制御を追加。追加のみ。

### 追加
- `ReviewPromptService`: 頼んでよいかの判定（`evaluate`）と、レビュー画面を出す処理（`maybeRequest`）。初回起動からの日数・良い体験の数・前回からの間隔・生涯の上限・断られた直後・同じ起動中にもう頼んだ、を見る。条件は `ReviewPromptRules`（既定は控えめ）
- `ReviewBackend`（ストアのレビュー画面の窓口。実処理はアプリが実装。キットはレビューのプラグインに依存しない）・`FakeReviewBackend`
- `ReviewStore`（`InMemoryReviewStore`・`SharedPreferencesReviewStore(appId)`）・`ReviewState`・`ReviewDecision`・`reviewPromptServiceProvider`
- `showReviewPrePrompt`: 頼む前の確認ダイアログ（「アプリを楽しんでいますか？」）。「はい」→レビュー画面、「いいえ」→レビューは頼まず `onNegative`（フィードバックへの案内など）、「あとで」→何もしない
- 文言（`KitStrings` に 4 項目）

## [0.26.0] - 2026-10-09

共通の設定画面を追加。追加のみ（既定の表示は変わらない）。

### 追加
- `SettingsScreen`: 設定タブの完成品。受験日（`ExamDateTile`）・購入（`PurchaseSection`）・表示モード・言語・片手・ながら学習・ご意見／不具合報告（`FeedbackFormPage`）・学習の引き継ぎ・このアプリについて（バージョンと免責）。項目は引数で出し分け、アプリ固有の項目は `extraSections`（`SettingsSection`）で足す
- `SettingsLanguage`（言語の選択肢）
- 設定画面の文言（`KitStrings` に 25 項目＋`aboutVersion`）

### 変更
- `PurchaseSection`・`ExamDateTile` の文言を `KitStrings` 対応にした（日本語の既定は従来と同じ。英語に切り替えられる）

### 注意
- `SettingsScreen` の購入欄は `entitlementServiceProvider`、片手・ながら学習の欄は `handsFreeStoreProvider` の override が要る。使わないなら `showPurchase: false` / `showHandsFree: false`

## [0.25.1] - 2026-10-09

アクセシビリティの自動検査を追加し、見つかった不具合を直した。

### 修正
- `WardrobeScreen`: 衣装の行（`ListTile`）の右側のボタンが行の幅を使い切り、英語の長いボタン文言＋文字200%＋幅の狭い端末（320dp）でレイアウトが成り立たなくなる不具合。右側の幅に上限を付けた `Row` にした

### 追加（テストのみ）
- `test/accessibility_test.dart`: 主要な共通UI部品（17種）を、言語（ja/en）× 文字の大きさ（標準・200%）× 明暗で検査する。はみ出し（320dp も）・タップ領域（Android 48dp／iOS 44pt）・読み上げラベル・文字のコントラスト。検査自体が悪い部品を検知できることも確認する

## [0.25.0] - 2026-10-09

ja/en 以外の言語を、アプリ側から足せるようにした。追加のみ（既定の表示は変わらない）。

> 注意: この変更は、0.24.0（`PurchaseSection`・`ExamDateTile`）と同じ番号で `main` に入ってしまった。`v0.24.0` のタグは `PurchaseSection` のコミットを指し、この変更は含まない。番号を 0.25.0 に直した。

### 追加
- `KitStrings.copyWith`・`LabStrings.copyWith`: 一部の文言だけ差し替えた複製（ほかの言語の土台にも使える）
- `KitStrings.forLocale(locale, supported: {...})`: アプリが用意した言語を選べる（無い言語は従来どおり。en は英語、他は日本語）
- `KitStringsScope(labs:, mascotLines:)`: ラボ系の文言と推しのセリフも差し込める。省略時は従来どおり言語に応じた ja/en
- `MascotLines.forTone(custom:)`
- README に「言語を足す」手順を追加（あわせて、欠けていた「構成」の見出しを戻した）

## [0.24.0] - 2026-10-09

アプリごとに重複していた設定タブの部品を共通化する。追加のみで、既存 API に破壊的変更はない。

### 追加
- `PurchaseSection`: 設定タブの「購入」欄（広告非表示・プレミアムの購入と復元）。`entitlementServiceProvider` / `entitlementStateProvider` を使う。見出しの大きさは `titleStyle` で渡す
- `ExamDateTile`: 受験日の入力欄（日付ピッカーと解除）。状態は持たず、保存は `onChanged` を受けたアプリ側

## [0.23.0] - 2026-10-09

共有カードの多言語化（ja/en）。追加のみ。

### 追加
- `PassShareCard` がブランド名（日本語「うかラボ」／英語「Qualab」）・既定の一言（合格しました！／I passed!）・日付表記（2026年10月9日／Oct 9, 2026）を `KitStrings` で切り替える。`strings:` 引数でも指定可（ダイアログ内では呼び出し側の文言を引き継ぐ）
- `ShareCardData.message` は null 許容に変更（null なら既定の一言。渡せば従来どおり優先）。`ShareCardData.dateText` は日本語表記のまま残す（言語に合わせるなら `KitStrings.shareDate`）

### 注意
- 英語のブランド名は「Qualab」（`KitStrings.en` の `shareCardBrand`）

## [0.22.0] - 2026-10-09

多言語化（ja/en）の残りの画面部品を対応。追加のみ（文言の引数は null 許容になり、渡せば従来どおり優先）。

### 追加
- `ChoiceTile`・`HandsFreeChoiceTile`（正解／不正解・読み上げ用ラベルの区切り）、`ExplanationPanel`（見出し・出典）、`UkalabShell`（下部タブ）、`ReadAloudButton`（ツールチップ）、`showMockRecordDialog`（学習の記録カード。`strings:` 引数あり）が `KitStrings` に対応
- `UkalabShell.labels` は null 許容に変更（null なら `KitStrings.tabLabels`。日本語は従来の `defaultLabels` と同じ）

### 注意
- 共有カード画像の文言（「うかラボ」・日付表記）と、衣装名・資格名などのカタログは日本語のまま

## [0.21.0] - 2026-10-09

片手・ながら学習モード（大きなボタン・下部配置・端末標準の音声読み上げ）。追加のみで、既存 API に破壊的変更はない。

### 追加
- `HandsFreeSettings`（有効／問題を読む／解説を読む／読み上げの速さ 0.5〜1.5）・`HandsFreeStore`
  （`InMemoryHandsFreeStore`・`SharedPreferencesHandsFreeStore(appId)`）・`handsFreeProvider`
  （`HandsFreeNotifier`: `load`・`setEnabled` など）。壊れた保存データでも読めた項目だけを使う
- `SpeechBackend`（音声合成の窓口。端末標準の読み上げをアプリが実装して渡す。キットは音声プラグインに依存しない）・
  `FakeSpeechBackend`（テスト用）・`HandsFreeSpeaker`（設定に従って問題・解説を自動で読む。失敗しても例外を出さない）・
  `questionReadAloudText`（問題文と選択肢を読み上げ用の文にする）
- `HandsFreeChoiceTile`（高さ 72pt 以上の大きな選択肢ボタン）・`ReadAloudButton`・
  `HandsFreeQuestionLayout`（問題文は上、選択肢は下に寄せる骨組み）

### 注意
- 数式・図の読み上げは対象外

## [0.20.0] - 2026-10-09

学習の引き継ぎ（機種変更で学習履歴・衣装・コインを復元）。追加のみで、既存 API に破壊的変更はない。

### 追加
- `LearningTransfer`（`backup()` / `restore()`）: 部品ごとに保存・復元する。復元は統合で、端末内を消さず、冪等。
  1つの部品の失敗で他を止めず、例外は出さない（`TransferResult`: `success` / `partial` / `failed`、
  `failed`・`missing`・`nothingToRestore`）
- `TransferSource`（部品の型）・`FunctionTransferSource`（関数で作る。学習履歴などアプリ側のデータ用）・
  `CoinTransferSource`（コイン台帳）・`OutfitTransferSource`（合格・準備完了・着ている衣装）
- `TransferRemote`・`InMemoryTransferRemote`・`FirebaseTransferRemote(uid:, examId:)`:
  保存先は `users/{uid}/exams/{examId}/transfer/{partId}`（共通ルールに含まれ、ルール変更は不要）
- `OutfitService.toStateJson()` / `mergeState()`: 解放状態の書き出しと統合（合格・準備完了は足し合わせ、
  着ている衣装は端末内を優先）

### 注意
- 1部品は Firestore の1MB上限まで。学習履歴が大きいアプリは、部品を分けるか期間で切り分ける

## [0.19.0] - 2026-10-09

コイン同期をアプリに組み込める形にした。

### 追加
- `FirebaseCoinRemote(uid:, examId:)`: 台帳の Firestore 実装。保存先は `users/{uid}/exams/{examId}/coin/ledger`（既存の共通ルールに含まれ、ルール変更は不要）
- `CoinNotifier.syncWith(remote, minInterval:)`: 同期して画面の状態を更新する。間隔内の再同期・同期中はスキップ（null）、失敗は `CoinSyncResult.failed`（例外なし）
- 組み込み手順を README に追加

## [0.18.0] - 2026-10-09

多言語化の対象を拡大。

### 追加
- `WardrobeScreen`・`OshiHomeCard`・`outfitLockedReason` が `KitStrings` に対応（`WardrobeScreen(strings:)`・`outfitLockedReason(strings:)`）。`OshiHomeCard` から開く着替え画面・合格報告には、カードの文言を引き継ぐ
- `WardrobeScreen.title` は null 許容に変更（渡せば従来どおり優先）
- 衣装名・マスコットのセリフ・推し選択画面は日本語のまま（次回以降）

## [0.17.0] - 2026-10-09

多言語化の対象を拡大。

### 追加
- `FeedbackFormPage`・`showPassReportDialog` が `KitStrings` に対応（`strings:` 引数でも指定可）。文言を `KitStrings` に追加
- 注意: `KitStringsScope` は `MaterialApp.builder` など Navigator より上に置く（`home` の内側だと積まれた画面・ダイアログに届かない）

## [0.16.0] - 2026-10-09

多言語化の土台（日本語・英語）を追加。

### 追加
- `KitStrings`（ja/en）・`KitStringsScope`: 囲んだ配下のキットの既定文言を切り替える。囲まなければ日本語のまま（互換）
- 対応: `CoinBreakdownCard`・`coinEventLabel`・`ErrorState`・`StreakBadge`・`ResultSummary`（文言の引数は null 許容に変更。渡せば従来どおり優先）

## [0.15.0] - 2026-10-09

コイン台帳の共通アカウント同期を追加。

### 追加
- `CoinRemote`（サーバー側の保存先・アプリが実装）と `CoinSync.sync()`: サーバー台帳を統合して書き戻す。失敗時は端末内を変えない

## [0.14.0] - 2026-10-07

縦長の部屋の背景・部屋の小物・場面ポーズの Lv2〜5 を追加。

### 追加
- `UkalabOshiRoom(portrait: true)`: 縦長の背景（壁紙向け・736×1120）。`UkalabRooms.image(room, portrait: true)`・`UkalabRooms.portraitAspectRatio`。画像は `assets/mascot/rooms/roomv_<name>.webp`（7枚・約0.35MB）
- `UkalabProp` / `UkalabProps.image(prop)`: 部屋の小物12種（本棚・黒板・トロフィー・鉢植え・ランプ・地球儀・時計・フラスコ棚・工具箱・そろばん・額縁・バッジ盤）。透過の画像 `assets/mascot/props/prop_<name>.webp`（約0.4MB）。置き方（いつ何を出すか）はアプリ側で決める

### 変更
- 場面別ポーズ（前日・おかえり・連続）が Lv1〜5 のそれぞれの姿で出る（Lv2=名札・Lv3=かばん+ピン・Lv4=腕章・Lv5=卒業帽+ケープ）。これまで Lv2 以上は通常画像に戻っていた。`UkalabCharacters.sceneFile(id, scene, [stage])` の引数追加（既定は Lv1 で互換）
- 画像は `assets/mascot/<id>/scenes/<id>_lv<2-5>_<eve|back|streak>.webp`（48枚・約1.7MB・460×700）

### 注意
- アプリサイズは約 +2.5MB（場面 1.7・背景 0.35・小物 0.4）

## [0.13.0] - 2026-10-07

推しの部屋（分野別の背景）と、案内役ポーズを追加。

### 追加
- `UkalabOshiRoom` / `UkalabOshiRoom.forCert`: 部屋の背景の上に選んだ推し（衣装・場面ポーズ込み）を立たせた絵。壁紙・合格祝いカードの元になる（保存は `RepaintBoundary` + `toImage`）
- `UkalabRoom`（general / it / ai / accounting / safety / language / transport）と `UkalabRooms.forCert(cert)`・`UkalabRooms.image(room)`。画像は `assets/mascot/rooms/room_<name>.webp`（1120×736・7枚・約0.4MB）
- `MascotScene.guidePoint / guideThink / guideTeach`: 案内役のポーズ（指さし／考える／白紙の本を見せる）。`MascotWidget(scene: ...)` で使う。レベルに関係なく出る（Lv1 の絵）。画像は `assets/mascot/<id>/guide/`（4体×3枚・約0.6MB）。`MascotScene.isGuide` で判別

### 注意
- 前日・おかえり・連続の場面ポーズは従来どおり Lv1 のみ。案内役だけレベルに関係なく出る
- アプリサイズは約 +1MB

## [0.12.0] - 2026-10-07

推しの場面別ポーズ（前日の応援・おかえり・連続学習）を追加。

### 追加
- `MascotScene`（eve / welcomeBack / streak）・`CharacterPack.sceneImageBuilder`・`UkalabCharacters.sceneImage`。画像は `assets/mascot/<id>/scenes/<id>_lv1_<eve|back|streak>.webp`（4体×3枚、約0.7MB）
- `MascotWidget(scene: ...)`: 画像パックで衣装を着ていないときに場面別ポーズを出す（衣装が優先）
- `UkalabOshiCard` は、試験前日・久しぶり（おかえり）・連続学習（3日以上）のひとことと同時に、場面別ポーズを自動で出す

### 注意
- 場面別ポーズは Lv1（私服）だけ。Lv2 以上は null を返し、従来の通常画像のまま（Lv2〜5 の場面画像は今後追加）

## [0.11.0] - 2026-10-07

推しカードの完成品をキットに追加（アプリごとの重複コードを不要にする）。

### 追加
- `UkalabOshiCard`: ホームに置く推しカード。`cert`・`stage`・`appId` を渡すだけで、選択中の推し・衣装・ひとこと（試験日/連続/おかえり）・メニュー（推しを選ぶ/着替え/合格報告/表示切替）・学習コイン・連続日数が出る。表示設定は `ukalab.oshi.display.<appId>` に保存

### 使い方
- 成長段階 `stage` は習得度から `MasteryModel.standard.stageOf(...)` でアプリが計算して渡す。共有ボタンが要るアプリは `onShare` を渡す

## [0.10.1] - 2026-10-07

推しの衣装画像を簿記3級・危険物乙4・生成AIパスポートに追加。

### 追加
- `UkalabCharacters.costumedCerts` に boki3 / hazmat4 / gen_ai_passport を追加。4体×3資格×(通常・合格記念・試験日)=36枚（約2.2MB）。衣装画像のある資格は計6つ

## [0.9.0] - 2026-10-07

推し（AI画像の4体）を共通キットに追加。

### 追加
- `UkalabCharacters`（kai/mio/moka/mike の `CharacterPack`・Lv画像・顔アイコン・衣装画像）。画像は `assets/mascot/`（約5MB。漢字検定・バイク免許・G検定の衣装つき）
- `CharacterPack.outfitImageBuilder`（衣装を着た姿の画像。`MascotWidget` が `outfit` 指定時に使う）
- `selectedCharacterPackProvider`（選んだ推しを `ukalab.mascot.selected` に端末内保存）と `CharacterSelectScreen`（選択画面）

### 使い方
- アプリは `ref.watch(selectedCharacterPackProvider)` の値を `MascotWidget`／`WardrobeScreen` の `pack` に渡す。選択画面は設定から `CharacterSelectScreen` を開く
- 衣装画像がない資格は私服の画像のまま

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

### 修正
- アプリアイコン: Android adaptive の前景を中央66%→56%に変更。円形マスクで「うかラボ」「試験名」の端が欠けていた

### 追加
- アプリアイコン: 中央のシンボルを PNG 画像で差し込めるようにした（`tools/icon_gen`、spec の `symbol_image`）。単色背景に白で描いた絵から白いシルエットを自動で抜き出す（Canva 等で作った絵を想定）
- アプリアイコン: 「うかラボ」の左に、合格の象徴「桜」を添えた（`tools/icon_gen`、`symbols/sakura.svg`）。桜とタイトルをまとめて中央に置く。最小サイズ版（上段なし）には入れない

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

v0.2 追加仕様 §1〜6（テーマ・共通UI部品・推し・学習コイン・衣装と資格連動・アイコン生成）。§7（学習体験の型）は ukalab_core 側で v0.3 以降。

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
