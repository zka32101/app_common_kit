// 全アプリ共通「バグ報告・改善要望」フォーム機能の型。
//
// app_common_kit は cloud_firestore や firebase_auth に依存しない
// （cross_promo_kit と同じく依存を絞る設計方針）。実際の送信処理（Firestore書き込み等）、
// userId の取得は各アプリ側が FeedbackNotifier.setSubmitHandler() 経由・
// submitFeedback() の引数で注入する。
//
// Firestore に書き込まれた FeedbackReport は、Cloud Functions 側で GitHub Issues API を
// 呼び出すことで GitHub Issue に自動変換することを想定している（type を issue label に
// マッピングする等の変換ロジックは Cloud Functions 側の責務）。

/// 報告の種別。
enum FeedbackType {
  bug, // 不具合報告
  feature, // 改善要望
  other, // その他
}

extension FeedbackTypeLabel on FeedbackType {
  String get label => switch (this) {
        FeedbackType.bug => '不具合報告',
        FeedbackType.feature => '改善要望',
        FeedbackType.other => 'その他',
      };

  /// GitHub Issue 化する際に付与する label 名。
  String get githubLabel => switch (this) {
        FeedbackType.bug => 'bug',
        FeedbackType.feature => 'enhancement',
        FeedbackType.other => 'feedback',
      };
}

/// 1件のバグ報告・改善要望。
class FeedbackReport {
  final String id;
  final FeedbackType type;
  final String title;
  final String description;
  final String appName; // どのアプリからの報告か（例: 'kokugo-kore'）
  final String appVersion;
  final String platform; // 'iOS' / 'Android' 等
  final DateTime createdAt;
  final String? userId; // アプリ側で取得したユーザー識別子（匿名認証のUID等）
  final String status; // 'open' / 'reviewing' / 'resolved' など。初期値'open'
  final String? githubIssueUrl; // Cloud Functions が Issue 化した後に埋め込む

  const FeedbackReport({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.appName,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    this.userId,
    this.status = 'open',
    this.githubIssueUrl,
  });

  FeedbackReport copyWith({
    String? id,
    FeedbackType? type,
    String? title,
    String? description,
    String? appName,
    String? appVersion,
    String? platform,
    DateTime? createdAt,
    String? userId,
    String? status,
    String? githubIssueUrl,
  }) =>
      FeedbackReport(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        appName: appName ?? this.appName,
        appVersion: appVersion ?? this.appVersion,
        platform: platform ?? this.platform,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
        status: status ?? this.status,
        githubIssueUrl: githubIssueUrl ?? this.githubIssueUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'appName': appName,
        'appVersion': appVersion,
        'platform': platform,
        'createdAt': createdAt.toIso8601String(),
        'userId': userId,
        'status': status,
        'githubIssueUrl': githubIssueUrl,
      };

  factory FeedbackReport.fromJson(Map<String, dynamic> json) => FeedbackReport(
        id: json['id'] as String,
        type: FeedbackType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => FeedbackType.other,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        appName: json['appName'] as String,
        appVersion: json['appVersion'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        userId: json['userId'] as String?,
        status: json['status'] as String? ?? 'open',
        githubIssueUrl: json['githubIssueUrl'] as String?,
      );
}
