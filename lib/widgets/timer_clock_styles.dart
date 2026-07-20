import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'seven_segment_clock.dart';

/// 計測画面をスワイプして選べる時計のスタイル。
/// `build` は、そのスタイル用の見た目を作って返す
/// （時計の文字だけでなく、背景の質感までスタイルごとに変える）。
class TimerClockStyle {
  final String name;
  final Widget Function(BuildContext context, String timeText, double baseSize, Color fallbackColor) build;
  const TimerClockStyle(this.name, this.build);
}

final List<TimerClockStyle> timerClockStyles = [
  // ① 現在のスタイル（丸みのある数字。アプリの基本フォント）
  TimerClockStyle('丸み（現在）', (context, text, size, color) {
    return Text(text, style: GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w800, color: color));
  }),

  // ② デジタル（近未来風）
  TimerClockStyle('デジタル', (context, text, size, color) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: size * 0.9,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: const Color(0xFF8BE0FF),
        shadows: [Shadow(color: const Color(0xFF8BE0FF).withOpacity(.7), blurRadius: 18)],
      ),
    );
  }),

  // ③ レトロLCD（電卓風）
  TimerClockStyle('レトロLCD', (context, text, size, color) {
    return Text(
      text,
      style: GoogleFonts.shareTechMono(
        fontSize: size * 0.85,
        color: const Color(0xFF7CFF7C),
        shadows: [Shadow(color: const Color(0xFF7CFF7C).withOpacity(.6), blurRadius: 10)],
      ),
    );
  }),

  // ④ 手書き風
  TimerClockStyle('手書き風', (context, text, size, color) {
    return Text(text, style: GoogleFonts.caveat(fontSize: size * 1.05, fontWeight: FontWeight.w700, color: const Color(0xFFE2613B)));
  }),

  // ⑤ 筆文字・マーカー風
  TimerClockStyle('マーカー風', (context, text, size, color) {
    return Text(text, style: GoogleFonts.permanentMarker(fontSize: size * 0.72, color: const Color(0xFF423E99)));
  }),

  // ⑥ タイプライター
  TimerClockStyle('タイプライター', (context, text, size, color) {
    return Text(text, style: GoogleFonts.specialElite(fontSize: size * 0.82, color: const Color(0xFF3C3835)));
  }),

  // ⑦ ネオンサイン
  TimerClockStyle('ネオン', (context, text, size, color) {
    const neon = Color(0xFFFF6EC7);
    return Text(
      text,
      style: GoogleFonts.monoton(
        fontSize: size * 0.6,
        color: neon,
        shadows: [
          Shadow(color: neon.withOpacity(.9), blurRadius: 10),
          Shadow(color: neon.withOpacity(.6), blurRadius: 24),
        ],
      ),
    );
  }),

  // ⑧ ミニマル極細
  TimerClockStyle('ミニマル極細', (context, text, size, color) {
    return Text(text, style: GoogleFonts.sora(fontSize: size * 0.85, fontWeight: FontWeight.w200, letterSpacing: 4, color: color));
  }),

  // ⑨ 太字インパクト
  TimerClockStyle('太字インパクト', (context, text, size, color) {
    return Text(text, style: GoogleFonts.archivoBlack(fontSize: size * 0.78, color: color));
  }),

  // ⑩ ドット・ピクセル風
  TimerClockStyle('ピクセル風', (context, text, size, color) {
    return Text(text, style: GoogleFonts.pressStart2p(fontSize: size * 0.46, color: const Color(0xFFFFD166)));
  }),

  // ⑪ エレガント・セリフ
  TimerClockStyle('エレガント', (context, text, size, color) {
    return Text(text, style: GoogleFonts.playfairDisplay(fontSize: size * 0.9, fontWeight: FontWeight.w700, color: color));
  }),

  // ⑫ LEDデジタル置き時計風（白黒・角ばった7セグメント）
  TimerClockStyle('LED置き時計', (context, text, size, color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D10),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: SevenSegmentClock(text: text, digitHeight: size * 0.62),
    );
  }),

  // ⑬ すりガラス風（白黒トーン）
  TimerClockStyle('すりガラス', (context, text, size, color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3E), Color(0xFF6E6E74), Color(0xFFAEAEB4)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.4), width: 1),
            ),
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                fontSize: size * 0.72,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black.withOpacity(.35), blurRadius: 6, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }),
];
