import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';

/// 学習タイマーのシート。スワイプでの dismiss は無効にしてあり、
/// 閉じる手段は ×ボタン（停止して保存してから閉じる）か、
/// 停止ボタンのみに統一しています（記録の保存し忘れを防ぐため）。
void showTimerSheet(BuildContext context, String taskId) {
  final bodyKey = GlobalKey<_TimerBodyState>();
  showAppSheet(
    context,
    title: '学習タイマー',
    isDismissible: false,
    enableDrag: false,
    actions: [
      IconButton(
        icon: const Icon(Icons.close, color: AppColors.ink),
        onPressed: () {
          bodyKey.currentState?.stopAndSave();
          Navigator.pop(context);
        },
      ),
    ],
    bodyBuilder: (ctx) => _TimerBody(key: bodyKey, taskId: taskId),
  );
}

class _TimerBody extends StatefulWidget {
  final String taskId;
  const _TimerBody({super.key, required this.taskId});

  @override
  State<_TimerBody> createState() => _TimerBodyState();
}

class _TimerBodyState extends State<_TimerBody> {
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_running) {
        _stopwatch.stop();
        _ticker?.cancel();
        _running = false;
      } else {
        _stopwatch.start();
        _running = true;
        _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
          if (mounted) setState(() => _elapsed = _stopwatch.elapsed);
        });
      }
    });
  }

  /// 停止して記録を保存する。タイマー画面の×ボタンからも呼ばれる。
  void stopAndSave() {
    if (!mounted) return;
    _ticker?.cancel();
    final seconds = _stopwatch.elapsed.inSeconds;
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _elapsed = Duration.zero;
    });
    if (seconds > 0) {
      context.read<AppState>().commitSession(widget.taskId, seconds);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('記録しました（${formatDuration(seconds)}）'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.taskById(widget.taskId);
    final totalSeconds = _elapsed.inSeconds;
    final sessions = t == null
        ? <StudySession>[]
        : ([...t.sessions]..sort((a, b) => b.date.compareTo(a.date)));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
      child: Column(
        children: [
          Text(t?.title ?? '', textAlign: TextAlign.center, style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(formatHMS(totalSeconds), style: AppTheme.mono(48, color: AppColors.ink)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Pressable(
              onTap: stopAndSave,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                child: const Icon(Icons.stop_rounded, color: AppColors.ink, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Pressable(
              onTap: _toggle,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
              ),
            ),
          ]),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('この記録について', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('停止すると学習記録として保存され、タスクの合計学習時間に加算されます。', style: AppTheme.body(12, color: AppColors.inkSoft)),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('これまでの記録', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('まだ記録がありません', style: AppTheme.body(12, color: AppColors.inkFaint)),
            )
          else
            Column(
              children: sessions.take(8).map<Widget>((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)}',
                        style: AppTheme.body(12, color: AppColors.inkSoft)),
                    Text(formatDuration(s.durationSeconds), style: AppTheme.mono(12, weight: FontWeight.w700)),
                  ]),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
