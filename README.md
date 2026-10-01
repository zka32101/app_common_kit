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
      ref: main
```

## 構成

```
lib/
  app_common_kit.dart          # エントリポイント（公開API）
  models/
    feedback_model.dart        # フィードバック（バグ報告・改善要望）モデル
  providers/
    feedback_provider.dart     # FeedbackNotifier（送信・オフラインキュー管理）
  widgets/
    feedback_form_page.dart    # フィードバック送信フォーム画面
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

### GitHub Issue 化（半自動連携）の構想

Firestore の `feedback` コレクションを **Cloud Functions の `onCreate` トリガー**で監視し、
GitHub Issues API（`POST /repos/{owner}/{repo}/issues`）を呼び出すことで、
アプリから送られたフィードバックを自動的に GitHub Issue 化する連携を想定しています。

- `FeedbackType.githubLabel`（`bug` → `bug`、`feature` → `enhancement`、`other` → `feedback`）
  を Issue の label にマッピング
- Issue タイトルは `[appName] title`、本文に `description` / `platform` / `appVersion` /
  `createdAt` を記載
- 作成した Issue の URL を Firestore 側の `githubIssueUrl` フィールドに書き戻す
  （`FeedbackReport.githubIssueUrl`）ことで、アプリ側からも対応状況を参照可能にする
- Cloud Functions 本体の実装は各アプリの Firebase プロジェクト側、または
  `shared_core/infrastructure` 配下での一元管理を検討中（未実装）

この Cloud Functions 部分は Flutter パッケージ本体の範囲外のため、本リポジトリには含めません。
