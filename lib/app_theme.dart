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

  // 「StudySync Calm」パレット：暖色のクリーム地に寄せて、Opal的な静けさを演出。
  static const _lightBg = Color(0xFFFBF6EF);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFF6F1E8);
  static const _lightInk = Color(0xFF241F2E);
  static const _lightInkSoft = Color(0xFF6E6678);
  static const _lightInkFaint = Color(0xFFACA3B0);
  static const _lightLine = Color(0xFFEAE1D3);

  static const _darkBg = Color(0xFF17141C);
  static const _darkSurface = Color(0xFF221E2A);
  static const _darkSurface2 = Color(0xFF272230);
  static const _darkInk = Color(0xFFF3EFE9);
  static const _darkInkSoft = Color(0xFFB4AABF);
  static const _darkInkFaint = Color(0xFF6F6678);
  static const _darkLine = Color(0xFF362F3D);

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

  // UIのメインカラー（設定で変更可能）。既定は落ち着いたラベンダー寄りの藍色。
  static Color indigo = const Color(0xFF6E5AA0);
  static Color indigoDeep = const Color(0xFF4E4074);
  static Color indigoSoft = const Color(0xFFE9E3F5);

  static const coral = Color(0xFFE2684A);
  static const coralSoft = Color(0xFFFBE2DA);
  static const sage = Color(0xFF5C9376);
  static const sageSoft = Color(0xFFE3EFE6);
  static const gold = Color(0xFFD2A24C);
  static const goldSoft = Color(0xFFF6EFD7);
  static const peach = Color(0xFFF3A874);
  static const peachSoft = Color(0xFFFBE4D2);

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
