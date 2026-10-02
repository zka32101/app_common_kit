import 'package:flutter/material.dart';

/// 問題文のカード。「第3問 / 10問」の進行表示つき。選択肢は [child] に並べる。
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.text,
    this.index,
    this.total,
    this.child,
  });

  final String text;

  /// 1始まりの問題番号。
  final int? index;
  final int? total;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  total == null ? '第$index問' : '第$index問 / $total問',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            Text(text, style: theme.textTheme.bodyLarge),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}
