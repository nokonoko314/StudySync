import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../state/app_state.dart';
import '../utils/curve_math.dart';
import 'root_shell.dart';

/// 起動時のアニメーション画面。
/// 忘却曲線（学習→復習で記憶が回復していく様子）が左から右へ描かれ、
/// その後アイコンとロゴが現れて、ホーム画面へフェードします。
///
/// データの読み込み（AppState.load）がアニメーションより長くかかった
/// 場合は、読み込みが終わるまで自然に待ってからホームへ移ります
/// （読み込み中に画面が切り替わって変な見え方をしないようにするため）。
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _introMinimumElapsed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _introMinimumElapsed = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ready = _introMinimumElapsed && state.loaded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: ready ? const RootShell() : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppColors.indigoDeep,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // フェーズ分け：0-0.55 曲線が描かれる／0.4-0.75 アイコン／0.6-1.0 文字
            final curveT = Curves.easeOutCubic.transform((t / 0.55).clamp(0.0, 1.0));
            final iconT = Curves.easeOutBack.transform(((t - 0.4) / 0.35).clamp(0.0, 1.0));
            final textT = Curves.easeOut.transform(((t - 0.6) / 0.4).clamp(0.0, 1.0));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 110,
                  child: CustomPaint(painter: _SplashCurvePainter(curveT)),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: iconT,
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * iconT,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.asset('assets/icon/icon.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: textT,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - textT)),
                    child: Text('StudySync', style: AppTheme.display(22, color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashCurvePainter extends CustomPainter {
  final double progress; // 0.0-1.0
  _SplashCurvePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final data = buildForgettingCurve([1, 3, 7, 14, 30]);
    if (data == null) return;

    const padL = 6.0, padR = 6.0, padT = 10.0, padB = 10.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    double x(double day) => padL + (day / data.totalDays) * plotW;
    double y(double v) => padT + (1 - v / 100) * plotH;

    final path = Path();
    for (var i = 0; i < data.points.length; i++) {
      final p = Offset(x(data.points[i].dx), y(data.points[i].dy));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    // PathMetric を使って、progress に応じた途中までだけを描画する
    // （曲線が左から右へ伸びていくアニメーションになる）。
    final metrics = path.computeMetrics().toList();
    final partial = Path();
    for (final metric in metrics) {
      partial.addPath(metric.extractPath(0, metric.length * progress), Offset.zero);
    }

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(partial, paint);

    // 描かれ終わった先端に、進行を示す小さな光点を置く
    if (progress > 0.02 && progress < 1.0) {
      for (final metric in metrics) {
        final len = metric.length * progress;
        if (len > 0 && len < metric.length) {
          final tangent = metric.getTangentForOffset(len);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, 4.5, Paint()..color = Colors.white);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashCurvePainter oldDelegate) => oldDelegate.progress != progress;
}
