import 'package:flutter/material.dart';

import '../outfit/readiness.dart';

/// 「準備完了まで」の進み具合を静かに見せるカード。責める表現は使わない。
class ReadinessProgressCard extends StatelessWidget {
  const ReadinessProgressCard({super.key, required this.progress});

  final ReadinessProgress progress;

  String get _message {
    if (progress.isReady) return '準備完了です。本番、応援しています';
    if (progress.masteryFraction >= 1.0) return '習得度は十分です。あとは模擬試験で合格点を超えるだけ';
    final left = progress.masteryPercentLeft;
    return progress.mockNeeded
        ? '習得度があと$left%、模擬試験の合格でそろいます'
        : '習得度があと$left%でそろいます';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('準備完了まで', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.masteryFraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 8),
            Text(_message, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
