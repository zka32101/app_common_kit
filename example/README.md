# example

`app_common_kit` の動作確認用アプリ。Web で動かし、Playwright で操作を確認する。

```sh
cd example
flutter pub get
flutter build web
(cd build/web && python3 -m http.server 8099) &
(cd e2e && npm ci && npx playwright install chromium)
node e2e/check.js e2e/shots   # ja/en の切替を確認し、スクリーンショットを保存
# 既存のブラウザを使うなら CHROMIUM_PATH=/path/to/chromium を付ける
```

Flutter Web は文字がキャンバスに描かれるため、アクセシビリティ（semantics）を有効化して文字を拾う。
見た目の確認はスクリーンショットで行う。

CI（`web-e2e` ジョブ）でも同じ手順で実行し、スクリーンショットを `e2e-screenshots` として保存する。

## 確認していること（`e2e/check.js`）
日本語と英語のそれぞれで、次を操作して確かめる（失敗すると終了コード 1）。

- ホーム: 連続学習・コイン内訳・結果・エラー表示の文言
- フィードバック画面・着替え・ショップ: ボタンから**積んだ画面**を開き、文言が届いていること（`KitStringsScope` を `MaterialApp.builder` に置く構成の確認）
- 片手モード: 選択肢をタップすると、押した方が不正解・正解の方が正解と出ること
- 推しカードのメニュー: 項目の文言と、そこから開く着替え画面に文言が引き継がれること
- ページエラーが出ないこと
