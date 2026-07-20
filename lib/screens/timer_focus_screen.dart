import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/pressable.dart';

/// 学習タイマーの全画面表示。
///
/// ここを閉じて他の画面に移動しても、計測は裏側（AppState）で続く。
/// 下部にミニタイマーバーが表示され続け、タップすればまたここに戻れる。
///
/// 設定で「計測中の省電力表示」がONのときは、黒背景に白文字だけの
/// シンプルな配色にする（有機ELディスプレイの節電のため）。
class TimerFocusScreen extends StatefulWidget {
  final String taskId;
  const TimerFocusScreen({super.key, required this.taskId});

  @override
  State<TimerFocusScreen> createState() => _TimerFocusScreenState();
}

class _TimerFocusScreenState extends State<TimerFocusScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.activeTimerTaskId != widget.taskId) {
      state.startTimer(widget.taskId);
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.taskById(widget.taskId);
    final running = state.activeTimerTaskId == widget.taskId;
    final elapsed = running ? state.activeTimerElapsedSeconds : 0;
    final sessions = t == null ? <StudySession>[] : ([...t.sessions]..sort((a, b) => b.date.compareTo(a.date)));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final amoled = state.settings.timerAmoledMode;

    final bg = amoled ? Colors.black : AppColors.bg;
    final fg = amoled ? Colors.white : AppColors.ink;
    final fgSoft = amoled ? Colors.white70 : AppColors.inkSoft;
    final fgFaint = amoled ? Colors.white38 : AppColors.inkFaint;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 18, 0),
            child: Row(children: [
              Pressable(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 26, color: fgSoft),
                ),
              ),
              const Spacer(),
            ]),
          ),
          Expanded(
            child: isLandscape
                ? _landscapeBody(state, t, running, elapsed, sessions, amoled, fg, fgSoft, fgFaint)
                : _portraitBody(state, t, running, elapsed, sessions, amoled, fg, fgSoft, fgFaint),
          ),
        ]),
      ),
    );
  }

  // ── 縦画面：これまで通りの1カラム表示 ──────────────────────────
  Widget _portraitBody(AppState state, Task? t, bool running, int elapsed, List<StudySession> sessions, bool amoled, Color fg, Color fgSoft, Color fgFaint) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(children: [
        const SizedBox(height: 10),
        _taskTitle(t, fgSoft),
        const SizedBox(height: 10),
        _clock(elapsed, size: 58, color: fg),
        const SizedBox(height: 6),
        _statusText(running, fgFaint),
        const SizedBox(height: 28),
        _controls(state, t, running, amoled, fg),
        const SizedBox(height: 32),
        Align(alignment: Alignment.centerLeft, child: _historyLabel(fgSoft)),
        const SizedBox(height: 8),
        _historyList(state, t, sessions, fg, fgSoft, fgFaint),
      ]),
    );
  }

  // ── 横画面：大きなデジタル時計を画面いっぱいに表示 ──────────────
  // 縦画面をそのまま伸ばすと余白ばかりで物足りなかったため、
  // 数字を大きく伸ばして横画面らしい「置き時計」のような見た目にした。
  // 記録一覧は「記録を見る」からポップアップで確認できる。
  Widget _landscapeBody(AppState state, Task? t, bool running, int elapsed, List<StudySession> sessions, bool amoled, Color fg, Color fgSoft, Color fgFaint) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _taskTitle(t, fgSoft),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _clock(elapsed, size: 108, color: fg),
        ),
        const SizedBox(height: 8),
        _statusText(running, fgFaint),
        const SizedBox(height: 22),
        _controls(state, t, running, amoled, fg),
        const SizedBox(height: 18),
        Pressable(
          onTap: () => _showHistoryDialog(context, state, t, sessions, amoled, fg, fgSoft, fgFaint),
          child: Text('記録を見る（${sessions.length}件）', style: AppTheme.body(12, weight: FontWeight.w700, color: fgFaint)),
        ),
      ]),
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
          child: SingleChildScrollView(
            child: _historyList(state, t, sessions, fg, fgSoft, fgFaint),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('閉じる', style: TextStyle(color: fgSoft))),
        ],
      ),
    );
  }

  Widget _taskTitle(Task? t, Color color) =>
      Text(t?.title ?? '', textAlign: TextAlign.center, style: AppTheme.body(14, weight: FontWeight.w700, color: color));

  Widget _clock(int elapsed, {required double size, required Color color}) =>
      Text(formatHMS(elapsed), style: AppTheme.mono(size, color: color));

  Widget _statusText(bool running, Color color) => Text(
        running ? 'この画面を閉じても、バックグラウンドで計測は続きます' : '停止中',
        textAlign: TextAlign.center,
        style: AppTheme.body(11.5, color: color),
      );

  Widget _controls(AppState state, Task? t, bool running, bool amoled, Color fg) {
    // 省電力表示のときは、塗りつぶしの色面をなるべく作らないよう
    // 白い枠線だけのボタンにする（黒背景を保ったまま操作できるように）。
    final stopDecoration = amoled
        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 1.5))
        : BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppColors.cardShadow);
    final playDecoration = amoled
        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5))
        : BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Pressable(
        onTap: () => setState(() => state.stopTimer()),
        child: Container(
          width: 72,
          height: 72,
          decoration: stopDecoration,
          child: Icon(Icons.stop_rounded, color: fg, size: 26),
        ),
      ),
      const SizedBox(width: 20),
      Pressable(
        onTap: () => setState(() {
          if (running) {
            state.stopTimer();
          } else if (t != null) {
            state.startTimer(t.id);
          }
        }),
        child: Container(
          width: 72,
          height: 72,
          decoration: playDecoration,
          child: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ),
      ),
    ]);
  }

  Widget _historyLabel(Color color) => Text('これまでの記録', style: AppTheme.body(12, weight: FontWeight.w700, color: color));

  Widget _historyList(AppState state, Task? t, List<StudySession> sessions, Color fg, Color fgSoft, Color fgFaint) {
    if (sessions.isEmpty) {
      return Text('まだ記録がありません', style: AppTheme.body(12, color: fgFaint));
    }
    return Column(
      children: sessions.take(10).map<Widget>((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)}',
                style: AppTheme.body(12, color: fgSoft)),
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
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: fgFaint),
                ),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}
