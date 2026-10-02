import 'package:flutter/material.dart';

/// 連続学習日数。罰を感じさせない表現（0日でも責めない）。
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.zeroText = '今日から始めよう'});

  final int days;
  final String zeroText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = days <= 0 ? zeroText : '$days日連続';
    return Semantics(
      label: days <= 0 ? zeroText : '連続学習 $days日',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: theme.textTheme.labelLarge)),
          ],
        ),
      ),
    );
  }
}
