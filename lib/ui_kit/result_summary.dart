import 'package:flutter/material.dart';

import 'progress_ring.dart';

/// 結果画面。得点と合格ラインを数字で示し、合否は✓／文言でも伝える。
class ResultSummary extends StatelessWidget {
  const ResultSummary({
    super.key,
    required this.correct,
    required this.total,
    this.passRatio,
    this.passedText = '合格ライン到達',
    this.notPassedText = 'あと少し。弱点を復習しよう',
    this.onRetry,
    this.retryLabel = 'もう一度',
    this.onClose,
    this.closeLabel = '閉じる',
  });

  final int correct;
  final int total;

  /// 合格ライン（0〜1）。null なら合否表示なし。
  final double? passRatio;
  final String passedText;
  final String notPassedText;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onClose;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total <= 0 ? 0.0 : correct / total;
    final line = passRatio;
    final passed = line != null && ratio >= line;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(value: ratio, size: 128, label: '正答率'),
        const SizedBox(height: 16),
        Text('$correct / $total 問正解', style: theme.textTheme.titleMedium),
        if (line != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(passed ? Icons.check_circle : Icons.flag_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(child: Text(passed ? passedText : notPassedText, style: theme.textTheme.bodyMedium)),
            ],
          ),
          Text('合格ライン ${(line * 100).round()}%', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 24),
        if (onRetry != null) FilledButton(onPressed: onRetry, child: Text(retryLabel)),
        if (onClose != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onClose, child: Text(closeLabel)),
        ],
      ],
    );
  }
}
