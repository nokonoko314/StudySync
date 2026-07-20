import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HTML プロトタイプと同じカラートークン。
/// 壁紙・UIカラーだけでなく、ダークモードの切り替えでも
/// これらの値を書き換えて、アプリ全体の見た目に反映している。
class AppColors {
  static Color bg = _lightBg;
  static Color surface = _lightSurface;
  static Color surface2 = _lightSurface2;
  static Color ink = _lightInk;
  static Color inkSoft = _lightInkSoft;
  static Color inkFaint = _lightInkFaint;
  static Color line = _lightLine;

  static const _lightBg = Color(0xFFF1F0F6);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFFAFAFC);
  static const _lightInk = Color(0xFF1E1B2E);
  static const _lightInkSoft = Color(0xFF5B5770);
  static const _lightInkFaint = Color(0xFFA19DB3);
  static const _lightLine = Color(0xFFE5E3EE);

  static const _darkBg = Color(0xFF17151F);
  static const _darkSurface = Color(0xFF211E2C);
  static const _darkSurface2 = Color(0xFF2A2636);
  static const _darkInk = Color(0xFFF1F0F6);
  static const _darkInkSoft = Color(0xFFB8B4C9);
  static const _darkInkFaint = Color(0xFF6F6B80);
  static const _darkLine = Color(0xFF383349);

  static bool isDark = false;

  /// ダークモードのON/OFFを切り替える。
  static void setDark(bool dark) {
    isDark = dark;
    bg = dark ? _darkBg : _lightBg;
    surface = dark ? _darkSurface : _lightSurface;
    surface2 = dark ? _darkSurface2 : _lightSurface2;
    ink = dark ? _darkInk : _lightInk;
    inkSoft = dark ? _darkInkSoft : _lightInkSoft;
    inkFaint = dark ? _darkInkFaint : _lightInkFaint;
    line = dark ? _darkLine : _lightLine;
  }

  // UIのメインカラー（設定で変更可能）。既定は元のインディゴ。
  static Color indigo = const Color(0xFF423E99);
  static Color indigoDeep = const Color(0xFF2C2A66);
  static Color indigoSoft = const Color(0xFFE8E6F6);

  static const coral = Color(0xFFE2613B);
  static const coralSoft = Color(0xFFFCE5DD);
  static const sage = Color(0xFF4F8868);
  static const sageSoft = Color(0xFFE2EFE8);
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFF6EFD7);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: (isDark ? Colors.black : const Color(0xFF1E1B2E)).withOpacity(isDark ? 0.28 : 0.06), blurRadius: 2, offset: const Offset(0, 1)),
      ];

  /// UIのメインカラーを変更する。淡色（Soft）・濃色（Deep）は
  /// 指定した色から自動で計算する。
  static void setAccent(Color base) {
    final hsl = HSLColor.fromColor(base);
    indigo = base;
    indigoDeep = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    indigoSoft = hsl.withLightness(isDark ? 0.24 : 0.93).withSaturation((hsl.saturation * (isDark ? 0.5 : 0.55)).clamp(0.0, 1.0)).toColor();
  }

  /// 教科の色（ドット・タグ・グラフに使用）
  static List<Color> get projectPalette => [
        indigo,
        sage,
        coral,
        gold,
        const Color(0xFF2E7D9A),
        const Color(0xFF9A4F8C),
      ];

  /// 壁紙のカラー候補（淡いトーンのみ。可読性のため）
  static List<Color> get wallpaperPalette => [
        bg,
        const Color(0xFFFDF6E3),
        const Color(0xFFE8F3EC),
        const Color(0xFFFCEFE6),
        const Color(0xFFEAF0FB),
        const Color(0xFFEFEAF7),
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
