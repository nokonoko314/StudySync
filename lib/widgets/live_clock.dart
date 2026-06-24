import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';

/// 「日にちと今の時間」を表示する小さなライブクロック。
/// OSのステータスバーとは別に、ホーム画面ヘッダーに置いて使います
/// （HTMLプロトタイプ内のブラウザ用ステータスバー再現は、実機では
/// OSが既に表示してくれるため、Flutter版では作っていません）。
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
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${pad2(now.hour)}:${pad2(now.minute)}',
            style: AppTheme.mono(15, weight: FontWeight.w700, color: AppColors.ink)),
        Text('${now.month}/${now.day}(${weekdayJp(now)})',
            style: AppTheme.body(10.5, weight: FontWeight.w600, color: AppColors.inkFaint)),
      ],
    );
  }
}
