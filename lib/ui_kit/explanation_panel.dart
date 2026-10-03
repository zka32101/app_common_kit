import 'package:flutter/material.dart';

/// 解説パネル。本文は17sp・行間1.6。出典があれば末尾に添える。
class ExplanationPanel extends StatelessWidget {
  const ExplanationPanel({
    super.key,
    required this.body,
    this.title = '解説',
    this.sourceRef,
    this.checkedAt,
    this.bodyWidget,
  });

  final String title;
  final String body;

  /// 出典（条文・公式資料）。
  final String? sourceRef;

  /// 出典を確認した日（YYYY-MM-DD）。
  final String? checkedAt;

  /// 本文の表示を差し替える（例: [TappableTermText] で用語をタップ可能にする）。
  /// 指定しなければ [body] をそのまま表示する。
  final Widget? bodyWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final src = sourceRef;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodyLarge,
              child: bodyWidget ?? Text(body, style: theme.textTheme.bodyLarge),
            ),
            if (src != null && src.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                checkedAt == null ? '出典: $src' : '出典: $src（$checkedAt 確認）',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
