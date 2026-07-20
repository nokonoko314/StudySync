import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/pressable.dart';
import '../screens/timer_focus_screen.dart';

/// 計測中、どの画面にいても表示され続けるミニタイマーバー。
/// タップするとフルスクリーンの計測画面に戻れるが、閉じたままでも
/// バックグラウンドで計測は継続する（開始時刻を保存して壁時計時間で
/// 経過を計算しているため）。
class TimerBar extends StatefulWidget {
  const TimerBar({super.key});

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
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
    final taskId = state.activeTimerTaskId;
    if (taskId == null) return const SizedBox.shrink();
    final task = state.taskById(taskId);
    final title = task?.title ?? '（削除されたタスク）';
    final project = task != null ? state.projectById(task.projectId) : null;

    return Pressable(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => TimerFocusScreen(taskId: taskId), fullscreenDialog: true),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppColors.indigo, boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 10, offset: const Offset(0, -2)),
        ]),
        child: Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: project?.color ?? Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Text(formatHMS(state.activeTimerElapsedSeconds), style: AppTheme.mono(15, color: Colors.white)),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => state.stopTimer(),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.stop_rounded, size: 15, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
