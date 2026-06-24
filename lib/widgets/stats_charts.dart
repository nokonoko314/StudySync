import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';

class ChartPoint {
  final String label;
  final int value; // 分
  ChartPoint(this.label, this.value);
}

class HBarItem {
  final String name;
  final Color color;
  final int minutes;
  HBarItem(this.name, this.color, this.minutes);
}

/// 日別／週別グラフ用の縦バーチャート。
class BarChartWidget extends StatelessWidget {
  final List<ChartPoint> data;
  const BarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.value).fold<int>(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final h = (d.value / maxVal * 110).clamp(4, 110).toDouble();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${d.value}', style: AppTheme.mono(9.5, color: AppColors.inkSoft)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: h,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 26),
                  decoration: const BoxDecoration(
                    color: AppColors.indigo,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7), bottom: Radius.circular(3)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d.label, style: AppTheme.body(10, weight: FontWeight.w700, color: AppColors.inkFaint)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// プロジェクト別／タスク別グラフ用の横バー一覧。
class HorizontalBarList extends StatelessWidget {
  final List<HBarItem> items;
  const HorizontalBarList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('データがありません', style: AppTheme.body(12, color: AppColors.inkFaint)),
      );
    }
    final maxVal = items.map((d) => d.minutes).fold<int>(1, (a, b) => b > a ? b : a);
    return Column(
      children: items.map((item) {
        final w = (item.minutes / maxVal).clamp(0.03, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            SizedBox(
              width: 78,
              child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(12.5, weight: FontWeight.w700)),
            ),
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: w,
                  child: Container(decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(99))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Text(formatDuration(item.minutes * 60),
                  textAlign: TextAlign.right, style: AppTheme.mono(11, color: AppColors.inkSoft)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

/// 完了率を表すドーナツチャート。
class CompletionDonut extends StatelessWidget {
  final int percent;
  const CompletionDonut({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(108, 108), painter: _DonutPainter(percent)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$percent%', style: AppTheme.mono(19, color: AppColors.ink)),
          Text('完了', style: AppTheme.body(10, color: AppColors.inkSoft)),
        ]),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int percent;
  _DonutPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final bgPaint = Paint()
      ..color = AppColors.surface2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17;
    final fgPaint = Paint()
      ..color = AppColors.sage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 9, bgPaint);
    final sweep = 2 * 3.14159265 * (percent / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 9), -3.14159265 / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent;
}
