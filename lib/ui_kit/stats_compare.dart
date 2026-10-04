import 'package:flutter/material.dart';

import '../stats/exam_stats_models.dart';

/// 模擬試験結果に添える全国集計との比較。集計が無ければ何も表示しない。
class StatsCompareWidget extends StatelessWidget {
  const StatsCompareWidget({
    super.key,
    required this.summary,
    required this.myScore,
  });

  final ExamStatsSummary? summary;
  final int myScore;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final deviation = s.deviationScoreFor(myScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('全国平均との比較', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('全国平均点 ${s.averageScore.toStringAsFixed(1)}点（${s.sampleCount}人分）'),
            Text('あなたの点数 $myScore点'),
            if (deviation != null) ...[
              const SizedBox(height: 4),
              Text(
                '偏差値 ${deviation.toStringAsFixed(1)}',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
