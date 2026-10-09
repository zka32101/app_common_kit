# example

`app_common_kit` の動作確認用アプリ。Web で動かし、Playwright で操作を確認する。

```sh
cd example
flutter pub get
flutter build web
(cd build/web && python3 -m http.server 8099) &
npm i playwright   # 既に入っていれば不要
node e2e/check.js ./shots   # ja/en の切替を確認し、スクリーンショットを保存
```

Flutter Web は文字がキャンバスに描かれるため、アクセシビリティ（semantics）を有効化して文字を拾う。
見た目の確認はスクリーンショットで行う。
