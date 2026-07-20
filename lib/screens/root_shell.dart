import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/app_settings.dart';
import '../app_theme.dart';
import '../nav_meta.dart';
import '../widgets/pressable.dart';
import '../widgets/timer_bar.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

const Map<String, AppScreen> _screenByKey = {
  'home': AppScreen.home,
  'calendar': AppScreen.calendar,
  'stats': AppScreen.stats,
  'settings': AppScreen.settings,
};

/// アプリの土台。背景（壁紙）、4画面の切り替え、ボトムナビを管理します。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 「端末に合わせる」設定のとき、OS側のライト/ダーク切り替えに追従する。
  @override
  void didChangePlatformBrightness() {
    context.read<AppState>().refreshSystemBrightness();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.loaded) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
      );
    }

    const screenWidgets = {
      AppScreen.home: HomeScreen(),
      AppScreen.calendar: CalendarScreen(),
      AppScreen.stats: StatsScreen(),
      AppScreen.settings: SettingsScreen(),
    };

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        Positioned.fill(child: _background(state.settings)),
        SafeArea(
          child: IndexedStack(
            index: AppScreen.values.indexOf(state.activeScreen),
            children: AppScreen.values.map((s) => screenWidgets[s]!).toList(),
          ),
        ),
      ]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TimerBar(),
          Container(
            decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.line))),
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: state.settings.navOrder.map((key) {
                  final meta = kNavMeta[key]!;
                  final screenEnum = _screenByKey[key]!;
                  final active = state.activeScreen == screenEnum;
                  return Expanded(
                    child: Pressable(
                      onTap: () => state.setActiveScreen(screenEnum),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(meta.icon, size: 21, color: active ? AppColors.indigo : AppColors.inkFaint),
                        const SizedBox(height: 3),
                        Text(meta.label, style: AppTheme.body(10.5, weight: FontWeight.w700, color: active ? AppColors.indigo : AppColors.inkFaint)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _background(AppSettings s) {
    switch (s.wallpaperType) {
      case WallpaperType.color:
        return Container(color: s.wallpaperColor != null ? Color(s.wallpaperColor!) : AppColors.bg);
      case WallpaperType.image:
        return s.wallpaperImagePath != null
            ? Image.file(File(s.wallpaperImagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
            : Container(color: AppColors.bg);
      case WallpaperType.defaultBg:
        return Container(color: AppColors.bg);
    }
  }
}
