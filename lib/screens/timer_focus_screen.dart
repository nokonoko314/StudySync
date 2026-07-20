import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/pressable.dart';
import '../widgets/timer_clock_styles.dart';
import '../widgets/color_picker_dialog.dart';

/// 学習タイマーの全画面表示。
///
/// 時計を左右にスワイプすると見た目のスタイルを切り替えられる。
/// スタイル選択後は、時計が画面いっぱいに表示され、課題名や状態は
/// 左上に小さく、操作ボタンは画面下ギリギリに配置される
/// （時計そのものを主役にするレイアウト）。
///
/// 右下の⚙から、時計の色やスタイル一覧、省電力表示などの詳細設定を開ける。
class TimerFocusScreen extends StatefulWidget {
  final String taskId;
  const TimerFocusScreen({super.key, required this.taskId});

  @override
  State<TimerFocusScreen> createState() => _TimerFocusScreenState();
}

class _TimerFocusScreenState extends State<TimerFocusScreen> {
  Timer? _ticker;
  Timer? _nameHideTimer;
  late final PageController _styleController;
  final GlobalKey _clockAreaKey = GlobalKey();
  bool _showStyleName = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.activeTimerTaskId != widget.taskId) {
      state.startTimer(widget.taskId);
    }
    _currentPage = state.settings.timerStyleIndex.clamp(0, timerClockStyles.length - 1);
    _styleController = PageController(initialPage: _currentPage);
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
    _scheduleHideName();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _nameHideTimer?.cancel();
    _styleController.dispose();
    super.dispose();
  }

  void _scheduleHideName() {
    _nameHideTimer?.cancel();
    setState(() => _showStyleName = true);
    _nameHideTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showStyleName = false);
    });
  }

  Future<void> _recordAndClose(AppState state, bool amoled) async {
    final recorded = state.stopTimer();
    if (recorded <= 0) {
      if (mounted) Navigator.pop(context);
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: amoled ? const Color(0xFF111111) : AppColors.surface,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text('記録しました', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: amoled ? Colors.white : AppColors.ink)),
          const SizedBox(height: 4),
          Text(formatDuration(recorded), style: AppTheme.mono(20, color: AppColors.indigo)),
        ]),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる'))),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.taskById(widget.taskId);
    final isActive = state.activeTimerTaskId == widget.taskId;
    final paused = isActive && state.isTimerPaused;
    final running = isActive && !paused;
    final displayElapsed = running ? state.activeTimerDisplayTotalSeconds : 0;
    final breakElapsed = paused ? state.activeTimerBreakElapsedSeconds : 0;
    final studySoFar = isActive ? state.activeTimerTotalStudySeconds : 0;
    final sessions = t == null ? <StudySession>[] : ([...t.sessions]..sort((a, b) => b.date.compareTo(a.date)));
    final amoled = state.settings.timerAmoledMode;

    final bg = amoled ? Colors.black : AppColors.bg;
    final fg = amoled ? Colors.white : AppColors.ink;
    final fgSoft = amoled ? Colors.white70 : AppColors.inkSoft;
    final fgFaint = amoled ? Colors.white38 : AppColors.inkFaint;
    final customColor = state.settings.timerClockColor != null ? Color(state.settings.timerClockColor!) : null;
    final clockColor = paused ? AppColors.gold : (customColor ?? fg);
    final seconds = paused ? breakElapsed : displayElapsed;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(children: [
          Positioned(
            top: 4,
            left: 4,
            right: 60,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pressable(
                onTap: () => Navigator.pop(context),
                child: SizedBox(width: 40, height: 40, child: Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: fgSoft)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(11.5, weight: FontWeight.w700, color: fgFaint)),
                  const SizedBox(height: 4),
                  _stateChip(paused),
                ]),
              ),
            ]),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: _scheduleHideName,
              child: Center(
                child: LayoutBuilder(builder: (context, constraints) {
                  final baseSize = constraints.biggest.shortestSide * 0.34;
                  return _clockArea(seconds, baseSize, clockColor);
                }),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedOpacity(
                opacity: _showStyleName ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(timerClockStyles[_currentPage].name, style: AppTheme.body(11, weight: FontWeight.w700, color: fgFaint)),
                ),
              ),
              _subLine(paused, studySoFar, fgFaint),
              const SizedBox(height: 14),
              _controls(state, t, running, paused, amoled, fg),
            ]),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Pressable(
              onTap: () => _showSettingsPanel(context, state, t, sessions, amoled, fg, fgSoft, fgFaint),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: fgFaint.withOpacity(.12), shape: BoxShape.circle, border: Border.all(color: fgFaint.withOpacity(.3))),
                child: Icon(Icons.tune_rounded, size: 16, color: fgSoft),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _clockArea(int seconds, double baseSize, Color color) {
    final text = formatHMS(seconds);
    return KeyedSubtree(
      key: _clockAreaKey,
      child: PageView.builder(
        controller: _styleController,
        itemCount: timerClockStyles.length,
        onPageChanged: (i) {
          setState(() => _currentPage = i);
          context.read<AppState>().setTimerStyleIndex(i);
          _scheduleHideName();
        },
        itemBuilder: (context, i) {
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: timerClockStyles[i].build(context, text, baseSize, color),
            ),
          );
        },
      ),
    );
  }

  Widget _stateChip(bool paused) {
    final label = paused ? '☕ 休憩中' : '● 学習中';
    final color = paused ? AppColors.gold : AppColors.indigo;
    final bgColor = paused ? const Color(0xFFF6EFD7) : AppColors.indigoSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: AppTheme.body(10, weight: FontWeight.w700, color: color)),
    );
  }

  Widget _subLine(bool paused, int studySoFar, Color color) {
    final text = paused ? '学習：${formatDuration(studySoFar)}（一時停止中はカウントされません）' : 'この画面を閉じても、バックグラウンドで計測は続きます';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(text, textAlign: TextAlign.center, style: AppTheme.body(10.5, color: color)),
    );
  }

  Widget _controls(AppState state, Task? t, bool running, bool paused, bool amoled, Color fg) {
    final recordDecoration = amoled
        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 1.5))
        : BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppColors.cardShadow);
    final toggleColor = paused ? AppColors.gold : AppColors.indigo;
    final toggleDecoration = amoled
        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))
        : BoxDecoration(color: toggleColor, shape: BoxShape.circle);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Pressable(
        onTap: () => _recordAndClose(state, amoled),
        child: Container(width: 64, height: 64, decoration: recordDecoration, child: Icon(Icons.stop_rounded, color: fg, size: 24)),
      ),
      const SizedBox(width: 18),
      Pressable(
        onTap: () => setState(() {
          if (paused) {
            state.resumeTimer();
          } else if (running) {
            state.pauseTimer();
          } else if (t != null) {
            state.startTimer(t.id);
          }
          _scheduleHideName();
        }),
        child: Container(
          width: 64,
          height: 64,
          decoration: toggleDecoration,
          child: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 28),
        ),
      ),
    ]);
  }

  void _showSettingsPanel(
    BuildContext context,
    AppState state,
    Task? t,
    List<StudySession> sessions,
    bool amoled,
    Color fg,
    Color fgSoft,
    Color fgFaint,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: amoled ? const Color(0xFF161616) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('時計の詳細設定', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg)),
              const SizedBox(height: 10),
              _settingsRow(
                icon: Icons.palette_outlined,
                label: '時計の色',
                trailing: Text('選択', style: TextStyle(color: fgFaint, fontWeight: FontWeight.w700)),
                color: fg,
                onTap: () async {
                  final current = state.settings.timerClockColor != null ? Color(state.settings.timerClockColor!) : AppColors.indigo;
                  final picked = await showColorPickerDialog(context, current);
                  if (picked != null) state.setTimerClockColor(picked);
                },
              ),
              _settingsRow(
                icon: Icons.refresh_rounded,
                label: '時計の色を既定に戻す',
                trailing: const SizedBox.shrink(),
                color: fg,
                onTap: () => state.setTimerClockColor(null),
              ),
              _settingsRow(
                icon: Icons.grid_view_rounded,
                label: 'スタイル一覧から選ぶ',
                trailing: Text(timerClockStyles[_currentPage].name, style: TextStyle(color: fgFaint, fontWeight: FontWeight.w700)),
                color: fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showStyleListSheet(context, amoled, fg, fgFaint);
                },
              ),
              _settingsRow(
                icon: Icons.battery_saver_outlined,
                label: '省電力表示（AMOLED）',
                trailing: Switch(
                  value: amoled,
                  activeColor: AppColors.indigo,
                  onChanged: (v) {
                    state.setTimerAmoledMode(v);
                    setSheetState(() {});
                  },
                ),
                color: fg,
                onTap: null,
              ),
              _settingsRow(
                icon: Icons.history_rounded,
                label: 'これまでの記録を見る（${sessions.length}件）',
                trailing: const SizedBox.shrink(),
                color: fg,
                onTap: () {
                  Navigator.pop(ctx);
                  _showHistoryDialog(context, state, t, sessions, amoled, fg, fgSoft, fgFaint);
                },
              ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Pressable(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: color.withOpacity(.7)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: color))),
          trailing,
        ]),
      ),
    );
  }

  void _showStyleListSheet(BuildContext context, bool amoled, Color fg, Color fgFaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: amoled ? const Color(0xFF161616) : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('スタイルを選ぶ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(timerClockStyles.length, (i) {
                    final active = i == _currentPage;
                    return Pressable(
                      onTap: () {
                        _styleController.jumpToPage(i);
                        setState(() => _currentPage = i);
                        context.read<AppState>().setTimerStyleIndex(i);
                        _scheduleHideName();
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          Icon(active ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: active ? AppColors.indigo : fgFaint),
                          const SizedBox(width: 10),
                          Text(timerClockStyles[i].name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: fg)),
                        ]),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showHistoryDialog(
    BuildContext context,
    AppState state,
    Task? t,
    List<StudySession> sessions,
    bool amoled,
    Color fg,
    Color fgSoft,
    Color fgFaint,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: amoled ? const Color(0xFF111111) : AppColors.surface,
        title: Text('これまでの記録', style: TextStyle(color: fg)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: _historyList(state, t, sessions, fg, fgSoft, fgFaint)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('閉じる', style: TextStyle(color: fgSoft))),
        ],
      ),
    );
  }

  Widget _historyList(AppState state, Task? t, List<StudySession> sessions, Color fg, Color fgSoft, Color fgFaint) {
    if (sessions.isEmpty) {
      return Text('まだ記録がありません', style: AppTheme.body(12, color: fgFaint));
    }
    return Column(
      children: sessions.take(10).map<Widget>((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)}', style: AppTheme.body(12, color: fgSoft)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(formatDuration(s.durationSeconds), style: AppTheme.mono(12, weight: FontWeight.w700, color: fg)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('記録を削除'),
                      content: Text('この記録（${formatDuration(s.durationSeconds)}）を削除しますか？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: AppColors.coral))),
                      ],
                    ),
                  );
                  if (confirm == true && t != null) {
                    state.deleteSession(t.id, s.id);
                  }
                },
                child: Padding(padding: const EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: fgFaint)),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}
