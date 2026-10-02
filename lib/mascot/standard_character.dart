import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mascot_models.dart';

/// 標準キャラ「フラスコの助手」のコード描画。画像ファイルは使わない。
///
/// 成長段階で装いが重なっていく:
/// Lv1 そのまま → Lv2 白衣 → Lv3 ゴーグル → Lv4 実験帽 → Lv5 博士帽。
/// 試験日が近いとき（7日以内）は、はちまきが付く。
class StandardCharacterPainter extends CustomPainter {
  StandardCharacterPainter({
    required this.stage,
    required this.expression,
    required this.accent,
    required this.outline,
    this.examPhase = ExamPhase.none,
    this.bob = 0,
  });

  final MascotStage stage;
  final MascotExpression expression;

  /// 液体の色（分野色または資格色）。
  final Color accent;
  final Color outline;
  final ExamPhase examPhase;

  /// 上下のゆれ（-1〜1）。動きを減らす設定のときは 0。
  final double bob;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2 + bob * s * 0.015);
    final u = s / 100.0;

    // フラスコ本体の輪郭: 首（細い）から下に広がる三角フラスコ
    final body = Path()
      ..moveTo(40 * u, 14 * u)
      ..lineTo(40 * u, 38 * u)
      ..lineTo(18 * u, 78 * u)
      ..quadraticBezierTo(14 * u, 90 * u, 28 * u, 90 * u)
      ..lineTo(72 * u, 90 * u)
      ..quadraticBezierTo(86 * u, 90 * u, 82 * u, 78 * u)
      ..lineTo(60 * u, 38 * u)
      ..lineTo(60 * u, 14 * u)
      ..close();

    // ガラス（うすく）
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: 0.55));

    // 液体: 段階が上がるほど増える
    final level = 0.28 + 0.12 * stage.index; // Lv1 0.28 … Lv5 0.76
    final liquidTop = 90 - 64 * level;
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTRB(0, liquidTop * u, 100 * u, 100 * u),
      Paint()..color = accent.withValues(alpha: 0.85),
    );
    canvas.restore();

    // 首の口（ふち）
    canvas.drawRRect(
      RRect.fromLTRBR(36 * u, 10 * u, 64 * u, 16 * u, Radius.circular(3 * u)),
      Paint()..color = outline,
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * u
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
    );

    _face(canvas, u);
    if (stage.index >= 1) _coat(canvas, u);
    if (stage.index >= 2) _goggles(canvas, u);
    if (stage == MascotStage.lv4) _labCap(canvas, u);
    if (stage == MascotStage.lv5) _doctorCap(canvas, u);
    if (examPhase == ExamPhase.close || examPhase == ExamPhase.eve || examPhase == ExamPhase.today) {
      _headband(canvas, u);
    }
    if (expression == MascotExpression.joy) _sparkles(canvas, u);
    canvas.restore();
  }

  void _face(Canvas c, double u) {
    final ink = Paint()
      ..color = const Color(0xFF1B2430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF1B2430);
    if (expression == MascotExpression.joy) {
      // にっこり目（上向きの弧）と大きめの口
      c.drawArc(Rect.fromCenter(center: Offset(43 * u, 64 * u), width: 8 * u, height: 8 * u), math.pi, math.pi, false, ink);
      c.drawArc(Rect.fromCenter(center: Offset(57 * u, 64 * u), width: 8 * u, height: 8 * u), math.pi, math.pi, false, ink);
      final mouth = Path()
        ..moveTo(44 * u, 71 * u)
        ..quadraticBezierTo(50 * u, 80 * u, 56 * u, 71 * u)
        ..close();
      c.drawPath(mouth, fill);
    } else {
      c.drawCircle(Offset(43 * u, 64 * u), 2.6 * u, fill);
      c.drawCircle(Offset(57 * u, 64 * u), 2.6 * u, fill);
      c.drawArc(Rect.fromCenter(center: Offset(50 * u, 70 * u), width: 10 * u, height: 7 * u), 0.2, math.pi - 0.4, false, ink);
    }
    // ほお
    final cheek = Paint()..color = const Color(0xFFFF9AA8).withValues(alpha: 0.45);
    c.drawCircle(Offset(36 * u, 70 * u), 3.2 * u, cheek);
    c.drawCircle(Offset(64 * u, 70 * u), 3.2 * u, cheek);
  }

  void _coat(Canvas c, double u) {
    final white = Paint()..color = Colors.white;
    final edge = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * u;
    // 左右の袖
    for (final dx in [-1.0, 1.0]) {
      final r = Rect.fromCenter(center: Offset((50 + dx * 33) * u, 72 * u), width: 11 * u, height: 17 * u);
      c.drawOval(r, white);
      c.drawOval(r, edge);
    }
    // えり（V字）
    final collar = Path()
      ..moveTo(40 * u, 38 * u)
      ..lineTo(50 * u, 52 * u)
      ..lineTo(60 * u, 38 * u)
      ..lineTo(56 * u, 36 * u)
      ..lineTo(50 * u, 44 * u)
      ..lineTo(44 * u, 36 * u)
      ..close();
    c.drawPath(collar, white);
    c.drawPath(collar, edge);
  }

  void _goggles(Canvas c, double u) {
    final strap = Paint()
      ..color = const Color(0xFF3A4452)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u;
    c.drawLine(Offset(34 * u, 30 * u), Offset(66 * u, 30 * u), strap);
    final lens = Paint()..color = const Color(0xFFBFE9FF).withValues(alpha: 0.9);
    for (final x in [44.0, 56.0]) {
      c.drawCircle(Offset(x * u, 30 * u), 5.5 * u, lens);
      c.drawCircle(Offset(x * u, 30 * u), 5.5 * u, strap..strokeWidth = 1.8 * u);
    }
  }

  void _labCap(Canvas c, double u) {
    final cap = Paint()..color = Colors.white;
    final edge = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * u;
    final r = RRect.fromLTRBR(37 * u, 2 * u, 63 * u, 12 * u, Radius.circular(5 * u));
    c.drawRRect(r, cap);
    c.drawRRect(r, edge);
  }

  void _doctorCap(Canvas c, double u) {
    final cap = Paint()..color = const Color(0xFF1B2430);
    final top = Path()
      ..moveTo(50 * u, 0)
      ..lineTo(74 * u, 7 * u)
      ..lineTo(50 * u, 14 * u)
      ..lineTo(26 * u, 7 * u)
      ..close();
    c.drawPath(top, cap);
    c.drawRect(Rect.fromLTRB(41 * u, 11 * u, 59 * u, 16 * u), cap);
    // 房
    c.drawLine(
      Offset(72 * u, 8 * u),
      Offset(76 * u, 20 * u),
      Paint()
        ..color = const Color(0xFFF5C400)
        ..strokeWidth = 1.8 * u
        ..strokeCap = StrokeCap.round,
    );
  }

  void _headband(Canvas c, double u) {
    final band = Paint()..color = const Color(0xFFD7282F);
    c.drawRRect(RRect.fromLTRBR(37 * u, 22 * u, 63 * u, 28 * u, Radius.circular(2 * u)), band);
    c.drawCircle(Offset(50 * u, 25 * u), 2.4 * u, Paint()..color = Colors.white);
    // 結び目
    c.drawLine(Offset(63 * u, 25 * u), Offset(70 * u, 20 * u), band..strokeWidth = 2 * u);
    c.drawLine(Offset(63 * u, 25 * u), Offset(70 * u, 30 * u), band..strokeWidth = 2 * u);
  }

  void _sparkles(Canvas c, double u) {
    final p = Paint()
      ..color = const Color(0xFFF5C400)
      ..strokeWidth = 1.8 * u
      ..strokeCap = StrokeCap.round;
    for (final (x, y) in [(14.0, 30.0), (88.0, 40.0), (84.0, 14.0)]) {
      c.drawLine(Offset((x - 3) * u, y * u), Offset((x + 3) * u, y * u), p);
      c.drawLine(Offset(x * u, (y - 3) * u), Offset(x * u, (y + 3) * u), p);
    }
  }

  @override
  bool shouldRepaint(covariant StandardCharacterPainter old) =>
      old.stage != stage ||
      old.expression != expression ||
      old.accent != accent ||
      old.outline != outline ||
      old.examPhase != examPhase ||
      old.bob != bob;
}
