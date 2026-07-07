import 'package:flutter/material.dart';
import 'pressable.dart';

/// Android/iOS用の「Googleでログイン」ボタン。
///
/// Web版はGoogle公式の描画ボタン（google_sign_in_web の renderButton）を
/// そのまま使っているが、Android/iOS側は以前は単色のボタンだったため
/// 見た目がバラバラだった。ここでは公式ボタンのガイドラインに沿った
/// 見た目（白背景・薄いグレーの枠線・Gロゴ・グレーの文字）を再現し、
/// Web版と統一感のあるデザインにしている。
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const GoogleSignInButton({super.key, required this.onPressed, this.label = 'Googleでログイン'});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFDADCE0), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 18, height: 18, child: _GoogleLogo()),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Googleの4色ロゴ（G）を簡易的にベクター再現したもの。
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    const strokeWidth = 3.6;
    final rect = Rect.fromCircle(center: center, radius: r - strokeWidth / 2);
    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const deg = 3.14159265 / 180;
    // 4色を四分割した円弧でGのリング部分を表現する（青・緑・黄・赤）
    canvas.drawArc(rect, -20 * deg, 110 * deg, false, arcPaint(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 90 * deg, 90 * deg, false, arcPaint(const Color(0xFF34A853)));
    canvas.drawArc(rect, 180 * deg, 70 * deg, false, arcPaint(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 250 * deg, 100 * deg, false, arcPaint(const Color(0xFFEA4335)));

    // Gの横棒
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(r * 0.15, r - strokeWidth / 2, r * 1.0, strokeWidth), barPaint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
