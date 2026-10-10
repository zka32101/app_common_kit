import 'package:flutter/material.dart';

/// 試験直前モードなど、締切までの残り日数を進捗バーで示す。
/// [daysLeft] が0に近いほど満たされる。
class CountdownProgressBar extends StatelessWidget {
  const CountdownProgressBar({
    super.key,
    required this.daysLeft,
    required this.windowDays,
    this.minHeight = 4,
  });

  /// 締切までの残り日数。
  final int daysLeft;

  /// 進捗の基準になる期間（日数）。
  final int windowDays;

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final value = windowDays <= 0
        ? 1.0
        : (1 - daysLeft / windowDays).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(minHeight),
      child: LinearProgressIndicator(value: value, minHeight: minHeight),
    );
  }
}
