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
