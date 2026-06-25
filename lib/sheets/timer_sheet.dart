import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';

/// 学習タイマーのシート。
///
/// 閉じ方は×ボタン・下にスワイプ・画面外タップのどれでもOKで、
/// どの方法で閉じても計測中の時間は自動で保存される（Stateのdispose
/// で保存するようにしているので、閉じ方の違いに関係なく必ず動く）。
void showTimerSheet(BuildContext context, String taskId) {
  showAppSheet(
    context,
    title: '学習タイマー',
    bodyBuilder: (ctx) => _TimerBody(taskId: taskId),
  );
}

class _TimerBody extends StatefulWidget {
  final String taskId;
  const _TimerBody({required this.taskId});

  @override
  State<_TimerBody> createState() => _TimerBodyState();
}

class _TimerBodyState extends State<_TimerBody> {
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _savedAlready = false;

  @override
  void dispose() {
    _ticker?.cancel();
    // シートがどう閉じられても（×、スワイプ、画面外タップ、戻る操作）
    // dispose は必ず呼ばれるので、ここで記録を確定させる。
    _saveNow();
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

  /// 手動の「停止」ボタンから呼ばれる：保存して、画面上の表示も0に戻す
  /// （シートはまだ閉じない。連続でもう一回計測できるように）。
  void _manualStop() {
    _ticker?.cancel();
    _saveNow();
    setState(() {
      _running = false;
      _elapsed = Duration.zero;
    });
  }

  /// 実際にAppStateへ記録を書き込む。dispose中・手動停止どちらからも呼ばれる。
  void _saveNow() {
    if (_savedAlready) return;
    final seconds = _stopwatch.elapsed.inSeconds;
    _stopwatch
      ..stop()
      ..reset();
    if (seconds <= 0) return;
    _savedAlready = true;
    try {
      context.read<AppState>().commitSession(widget.taskId, seconds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('記録しました（${formatDuration(seconds)}）'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
        ));
      }
    } catch (_) {
      // dispose の後など、contextが使えない場合はここに来るが、
      // commitSession 自体は AppState 側の話なので無視してよい
    }
    // 同じ画面でもう一度計測を始めたときのために、フラグを戻す
    _savedAlready = false;
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
              onTap: _manualStop,
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
            child: Text('停止する、または閉じると学習記録として保存され、タスクの合計学習時間に加算されます。', style: AppTheme.body(12, color: AppColors.inkSoft)),
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
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 14, color: AppColors.inkFaint),
                        ),
                      ),
                    ]),
                  ]),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
