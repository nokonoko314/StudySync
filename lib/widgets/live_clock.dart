import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';

/// ホーム画面ヘッダーに表示する、大きめのライブクロック。
/// 「今」の時刻を、見出し書体・グラデーションで温かみを出して表示する
/// （OSのステータスバーの時計とは別に、アプリ内の演出として置いている）。
class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNextTick();
  }

  /// 「次の分が始まる、ちょうどその瞬間」に更新されるようにする。
  /// 固定間隔（例：20秒ごと）だと、表示が実際の分の切り替わりより
  /// 最大で「その間隔の長さ」だけ遅れて見えてしまうため。
  void _scheduleNextTick() {
    final now = DateTime.now();
    final msUntilNextMinute = 60000 - (now.second * 1000 + now.millisecond);
    _timer = Timer(Duration(milliseconds: msUntilNextMinute), () {
      if (!mounted) return;
      setState(() {});
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppColors.ink, AppColors.indigo],
      ).createShader(bounds),
      child: Text(
        '${now.hour}:${pad2(now.minute)}',
        style: AppTheme.display(42, weight: FontWeight.w500, color: Colors.white),
      ),
    );
  }
}
