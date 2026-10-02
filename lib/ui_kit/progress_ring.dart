import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 進捗リング。中央に割合（%）を出す。色だけでなく数字でも伝える。
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.label,
    this.strokeWidth = 10,
  });

  /// 0.0〜1.0。範囲外は丸める。
  final double value;
  final double size;
  final double strokeWidth;

  /// 中央の下に出す短い文字（「習得度」など）。
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final percent = (v * 100).round();
    return Semantics(
      label: '${label ?? '進捗'} $percent%',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, theme.colorScheme.primary, theme.dividerColor, strokeWidth),
          child: Center(
            // 文字拡大でリングの内側に収まらないときは縮めて収める
            child: Padding(
              padding: EdgeInsets.all(strokeWidth + 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%', style: theme.textTheme.titleSmall),
                    if (label != null) Text(label!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.width);

  final double value;
  final Color color;
  final Color track;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(width / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    if (value > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.width != width;
}
