import 'package:flutter/material.dart';

/// 本物のLED電卓・置き時計のような、角ばった7セグメント表示を描画する。
/// フォントに頼らず、セグメントの多角形を直接描いているので、
/// 数字の角が丸まらない（かくかくした）見た目になる。
class SevenSegmentClock extends StatelessWidget {
  final String text; // 例: "00:24:18"
  final double digitHeight;
  const SevenSegmentClock({super.key, required this.text, this.digitHeight = 44});

  static const Map<String, String> _segments = {
    '0': 'abcdef',
    '1': 'bc',
    '2': 'abged',
    '3': 'abgcd',
    '4': 'fgbc',
    '5': 'afgcd',
    '6': 'afgedc',
    '7': 'abc',
    '8': 'abcdefg',
    '9': 'abcfgd',
  };

  @override
  Widget build(BuildContext context) {
    final digitWidth = digitHeight * 0.55;
    final colonWidth = digitHeight * 0.28;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: text.split('').map((ch) {
        if (ch == ':') {
          return SizedBox(
            width: colonWidth,
            height: digitHeight,
            child: CustomPaint(painter: _ColonPainter()),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: SizedBox(
            width: digitWidth,
            height: digitHeight,
            child: CustomPaint(painter: _DigitPainter(_segments[ch] ?? '')),
          ),
        );
      }).toList(),
    );
  }
}

class _DigitPainter extends CustomPainter {
  final String on;
  _DigitPainter(this.on);

  bool has(String s) => on.contains(s);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = w * 0.22; // セグメントの太さ

    final onPaint = Paint()..color = const Color(0xFFF4F5F7);
    final offPaint = Paint()..color = const Color(0xFF242628);

    Path seg(List<Offset> pts) {
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final pt in pts.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      return p;
    }

    void draw(String key, Path path) {
      canvas.drawPath(path, has(key) ? onPaint : offPaint);
    }

    // a: 上
    draw('a', seg([Offset(t, 0), Offset(w - t, 0), Offset(w - t * 0.5, t), Offset(t * 0.5, t)]));
    // f: 左上
    draw('f', seg([Offset(0, t * 0.3), Offset(t, t), Offset(t, h / 2 - t * 0.5), Offset(0, h / 2 - t * 0.9)]));
    // b: 右上
    draw('b', seg([Offset(w, t * 0.3), Offset(w - t, t), Offset(w - t, h / 2 - t * 0.5), Offset(w, h / 2 - t * 0.9)]));
    // g: 中央
    draw('g', seg([Offset(t * 0.5, h / 2), Offset(w - t * 0.5, h / 2), Offset(w - t, h / 2 + t * 0.5), Offset(t, h / 2 + t * 0.5)]));
    // e: 左下
    draw('e', seg([Offset(0, h / 2 + t * 0.9), Offset(t, h / 2 + t * 0.5), Offset(t, h - t), Offset(0, h - t * 0.3)]));
    // c: 右下
    draw('c', seg([Offset(w, h / 2 + t * 0.9), Offset(w - t, h / 2 + t * 0.5), Offset(w - t, h - t), Offset(w, h - t * 0.3)]));
    // d: 下
    draw('d', seg([Offset(t * 0.5, h), Offset(w - t * 0.5, h), Offset(w - t, h - t), Offset(t, h - t)]));
  }

  @override
  bool shouldRepaint(covariant _DigitPainter oldDelegate) => oldDelegate.on != on;
}

class _ColonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4F5F7);
    final r = size.width * 0.32;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.32), r, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.68), r, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
