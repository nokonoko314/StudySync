import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../screens/timer_focus_screen.dart';

/// 学習タイマーを開く。
///
/// 以前はボトムシートだったが、①バックグラウンドでも計測を続けたい
/// ②計測中も他の画面へ自由に移動したい、という要望に合わせて
/// 全画面表示に変更した。ここを閉じても、下部のミニタイマーバーから
/// いつでもまたこの画面に戻れる。
void showTimerSheet(BuildContext context, String taskId) {
  final state = context.read<AppState>();
  if (state.activeTimerTaskId != taskId) {
    state.startTimer(taskId);
  }
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => TimerFocusScreen(taskId: taskId), fullscreenDialog: true),
  );
}
