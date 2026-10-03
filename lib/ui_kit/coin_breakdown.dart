import 'package:flutter/material.dart';

import '../coin/coin_rules.dart';
import '../coin/coin_service.dart';

/// 付与の種別ごとの表示名。
String coinEventLabel(CoinEventType t) {
  switch (t) {
    case CoinEventType.newQuestion:
      return '新しい問題';
    case CoinEventType.coverageStep:
      return '網羅率アップ';
    case CoinEventType.accuracyMilestone:
      return '正答率の達成';
    case CoinEventType.accuracyBest:
      return '自己ベスト更新';
    case CoinEventType.reviewCorrected:
      return '復習で克服';
    case CoinEventType.dailyConsult:
      return '今日の相談';
    case CoinEventType.mockDone:
      return '模擬試験の実施';
    case CoinEventType.mockPass:
      return '模擬試験で合格点';
    case CoinEventType.mockBest:
      return '模擬試験の自己ベスト';
    case CoinEventType.streak:
      return '連続学習';
    case CoinEventType.passReport:
      return '合格報告';
  }
}

/// 結果画面のコイン内訳。学習の成長で貯まったコインだけを、控えめに見せる。
/// 付与がなければ何も出さない（責めない・煽らない）。
class CoinBreakdownCard extends StatelessWidget {
  const CoinBreakdownCard({super.key, required this.grants, this.title = '今回貯まった学習コイン'});

  final List<CoinGrant> grants;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final byType = <CoinEventType, (int, int)>{};
    for (final g in grants) {
      final cur = byType[g.event.type] ?? (0, 0);
      byType[g.event.type] = (cur.$1 + 1, cur.$2 + g.amount);
    }
    final total = grants.fold<int>(0, (a, g) => a + g.amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final e in byType.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value.$1 > 1 ? '${coinEventLabel(e.key)} ×${e.value.$1}' : coinEventLabel(e.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text('+${e.value.$2}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                Expanded(child: Text('合計', style: theme.textTheme.titleSmall)),
                Text('+$total', style: theme.textTheme.titleSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
