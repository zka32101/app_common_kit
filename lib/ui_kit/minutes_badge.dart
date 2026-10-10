import 'package:flutter/material.dart';

import 'kit_strings.dart';

/// 体験・コンテンツカードの所要時間バッジ（「約n分」）＋チェブロン。
/// カードの trailing に置く。
class MinutesBadge extends StatelessWidget {
  const MinutesBadge({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final s = KitStrings.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.minutesBadge(minutes),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
