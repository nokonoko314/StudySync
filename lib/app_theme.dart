import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HTML プロトタイプと同じカラートークン。
class AppColors {
  static const bg = Color(0xFFF1F0F6);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFAFAFC);
  static const ink = Color(0xFF1E1B2E);
  static const inkSoft = Color(0xFF5B5770);
  static const inkFaint = Color(0xFFA19DB3);
  static const indigo = Color(0xFF423E99);
  static const indigoDeep = Color(0xFF2C2A66);
  static const indigoSoft = Color(0xFFE8E6F6);
  static const coral = Color(0xFFE2613B);
  static const coralSoft = Color(0xFFFCE5DD);
  static const sage = Color(0xFF4F8868);
  static const sageSoft = Color(0xFFE2EFE8);
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFF6EFD7);
  static const line = Color(0xFFE5E3EE);

  static const cardShadow = [
    BoxShadow(color: Color(0x0F1E1B2E), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// プロジェクトの色（ドット・タグ・グラフに使用）
  static const projectPalette = [
    indigo,
    sage,
    coral,
    gold,
    Color(0xFF2E7D9A),
    Color(0xFF9A4F8C),
  ];

  /// 壁紙のカラー候補（淡いトーンのみ。可読性のため）
  static const wallpaperPalette = [
    bg,
    Color(0xFFFDF6E3),
    Color(0xFFE8F3EC),
    Color(0xFFFCEFE6),
    Color(0xFFEAF0FB),
    Color(0xFFEFEAF7),
  ];
}

/// フォントの使い分け：
/// - display（Shippori Mincho）: 画面タイトルなどの見出し
/// - body（Zen Kaku Gothic New）: 通常のUIテキスト
/// - mono（JetBrains Mono）: タイマー・統計などの数字
class AppTheme {
  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.shipporiMincho(
          fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.zenKakuGothicNew(
          fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, fontWeight: weight, color: color ?? AppColors.ink);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.indigo,
        secondary: AppColors.sage,
        error: AppColors.coral,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.zenKakuGothicNewTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
