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
class TimerFocusScreen extends StatefulWidget {
  final String taskId;
  const TimerFocusScreen({super.key, required this.taskId});

  @override
  State<TimerFocusScreen> createState() => _TimerFocusScreenState();
}

class _TimerFocusScreenState extends State<TimerFocusScreen> {
  Timer? _ticker;
  int? _targetMinutes; // 案E：クイックプリセット（25分/50分/自由=null）
  bool _autoStopped = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.activeTimerTaskId != widget.taskId) {
      state.startTimer(widget.taskId);
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      _checkAutoStop();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 目標時間（25分／50分）を設定しているとき、到達したら自動で停止・保存する。
  void _checkAutoStop() {
    final target = _targetMinutes;
    if (target == null || _autoStopped) return;
    final state = context.read<AppState>();
    if (state.activeTimerTaskId != widget.taskId) return;
    if (state.activeTimerElapsedSeconds >= target * 60) {
      _autoStopped = true;
      state.stopTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('目標の$target分が経過したので停止しました'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
        ));
      }
    }
  }

  void _selectTarget(int? minutes) {
    setState(() {
      _targetMinutes = minutes;
      _autoStopped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.taskById(widget.taskId);
    final running = state.activeTimerTaskId == widget.taskId;
    final elapsed = running ? state.activeTimerElapsedSeconds : 0;
    final sessions = t == null ? <StudySession>[] : ([...t.sessions]..sort((a, b) => b.date.compareTo(a.date)));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.bg,
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
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 26, color: AppColors.inkSoft),
                ),
              ),
              const Spacer(),
            ]),
          ),
          Expanded(
            child: isLandscape
                ? _landscapeBody(state, t, running, elapsed, sessions)
                : _portraitBody(state, t, running, elapsed, sessions),
          ),
        ]),
      ),
    );
  }

  // ── 縦画面：これまで通りの1カラム表示 ──────────────────────────
  Widget _portraitBody(AppState state, Task? t, bool running, int elapsed, List<StudySession> sessions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(children: [
        const SizedBox(height: 10),
        _taskTitle(t),
        const SizedBox(height: 10),
        _clock(elapsed, size: 58),
        const SizedBox(height: 6),
        _statusText(running),
        const SizedBox(height: 16),
        _presetSelector(),
        const SizedBox(height: 20),
        _controls(state, t, running),
        const SizedBox(height: 32),
        Align(alignment: Alignment.centerLeft, child: _historyLabel()),
        const SizedBox(height: 8),
        _historyList(state, t, sessions),
      ]),
    );
  }

  // ── 横画面：円形の進捗リングつきタイマーを左に、記録一覧を右に ──────
  // 縦画面のレイアウトをそのまま横に伸ばすと余白ばかりで物足りないため、
  // 2カラムに分けて画面全体を活かすレイアウトにしている。
  Widget _landscapeBody(AppState state, Task? t, bool running, int elapsed, List<StudySession> sessions) {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        flex: 6,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _taskTitle(t),
            const SizedBox(height: 14),
            _ringedClock(elapsed),
            const SizedBox(height: 10),
            _statusText(running),
            const SizedBox(height: 14),
            _presetSelector(),
            const SizedBox(height: 20),
            _controls(state, t, running),
          ]),
        ),
      ),
      VerticalDivider(width: 1, color: AppColors.line),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _historyLabel(),
            const SizedBox(height: 10),
            _historyList(state, t, sessions),
          ]),
        ),
      ),
    ]);
  }

  /// 案E：25分／50分のプリセット、または「自由」（時間を決めない、これまで通り）。
  Widget _presetSelector() {
    Widget chip(String label, int? minutes) {
      final active = _targetMinutes == minutes;
      return Pressable(
        onTap: () => _selectTarget(minutes),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.indigo : AppColors.surface2,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(label, style: AppTheme.body(12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      chip('25分', 25),
      chip('50分', 50),
      chip('自由', null),
    ]);
  }

  Widget _taskTitle(Task? t) =>
      Text(t?.title ?? '', textAlign: TextAlign.center, style: AppTheme.body(14, weight: FontWeight.w700, color: AppColors.inkSoft));

  Widget _clock(int elapsed, {required double size}) => Text(formatHMS(elapsed), style: AppTheme.mono(size, color: AppColors.ink));

  /// 横画面用：時計の周りの円弧で進み具合を見せる。
  /// 目標時間（25分／50分）を選んでいればその目標に対する進捗、
  /// 「自由」のときはこれまで通り「今の分の中の秒」の動きを表示する。
  Widget _ringedClock(int elapsed) {
    final target = _targetMinutes;
    final ratio = target != null ? (elapsed / (target * 60)).clamp(0.0, 1.0) : (elapsed % 60) / 60;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: ratio,
            strokeWidth: 4,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(AppColors.indigo),
          ),
        ),
        Text(formatHMS(elapsed), style: AppTheme.mono(38, color: AppColors.ink)),
      ]),
    );
  }

  Widget _statusText(bool running) => Text(
        running ? 'この画面を閉じても、バックグラウンドで計測は続きます' : '停止中',
        textAlign: TextAlign.center,
        style: AppTheme.body(11.5, color: AppColors.inkFaint),
      );

  Widget _controls(AppState state, Task? t, bool running) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Pressable(
        onTap: () => setState(() => state.stopTimer()),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
          child: Icon(Icons.stop_rounded, color: AppColors.ink, size: 26),
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
          decoration: BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
          child: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ),
      ),
    ]);
  }

  Widget _historyLabel() => Text('これまでの記録', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft));

  Widget _historyList(AppState state, Task? t, List<StudySession> sessions) {
    if (sessions.isEmpty) {
      return Text('まだ記録がありません', style: AppTheme.body(12, color: AppColors.inkFaint));
    }
    return Column(
      children: sessions.take(10).map<Widget>((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)}',
                style: AppTheme.body(12, color: AppColors.inkSoft)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(formatDuration(s.durationSeconds), style: AppTheme.mono(12, weight: FontWeight.w700)),
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
                  child: Icon(Icons.close, size: 14, color: AppColors.inkFaint),
                ),
              ),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}
