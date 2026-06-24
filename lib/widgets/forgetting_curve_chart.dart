import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/curve_math.dart';
import '../app_theme.dart';

/// 忘却曲線のプレビューを描く小さなチャート。
/// タスク詳細画面と「忘却曲線の手動設定」画面で使われます。
class ForgettingCurveChart extends StatelessWidget {
  final List<int> intervals;
  final double height;

  const ForgettingCurveChart({super.key, required this.intervals, this.height = 110});

  @override
  Widget build(BuildContext context) {
    final data = buildForgettingCurve(intervals);
    if (data == null) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            '復習間隔が設定されていないため、忘却曲線のプレビューはありません。',
            textAlign: TextAlign.center,
            style: AppTheme.body(12, color: AppColors.inkSoft),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CurvePainter(data)),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final CurveData data;
  _CurvePainter(this.data);

  static const _padL = 8.0, _padR = 8.0, _padT = 10.0, _padB = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padL - _padR;
    final plotH = size.height - _padT - _padB;
    double x(double day) => _padL + (day / data.totalDays) * plotW;
    double y(double v) => _padT + (1 - v / 100) * plotH;

    final axisPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_padL, size.height - _padB),
        Offset(size.width - _padR, size.height - _padB), axisPaint);

    final dashPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;

    for (final m in data.markers) {
      final mx = x(m.day);
      _drawDashedLine(canvas, Offset(mx, _padT), Offset(mx, size.height - _padB), dashPaint);
      canvas.drawCircle(Offset(mx, y(m.value)), 3, Paint()..color = AppColors.sage);

      final tp = TextPainter(
        text: TextSpan(
          text: '+${m.day.toInt()}日',
          style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppColors.inkFaint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mx - tp.width / 2, size.height - 14));
    }

    final path = Path();
    for (var i = 0; i < data.points.length; i++) {
      final p = Offset(x(data.points[i].dx), y(data.points[i].dy));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.indigo
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 3.0, gapLen = 3.0;
    final total = (end - start).distance;
    if (total == 0) return;
    final dir = (end - start) / total;
    double drawn = 0;
    while (drawn < total) {
      final segEnd = (drawn + dashLen) > total ? total : drawn + dashLen;
      canvas.drawLine(start + dir * drawn, start + dir * segEnd, paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => oldDelegate.data != data;
}
