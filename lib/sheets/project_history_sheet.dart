import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';

/// 「プロジェクト」（期末テストなど）を振り返るための画面。
/// タスク一覧ではなく、カレンダーのように「1日ごとの学習時間」を
/// 一目で見られる形にしている（濃さ＝その日に勉強した時間）。
void showProjectHistorySheet(BuildContext context, String groupName) {
  showAppSheet(context, title: groupName, bodyBuilder: (ctx) => _ProjectHistoryBody(groupName: groupName));
}

class _ProjectHistoryBody extends StatelessWidget {
  final String groupName;
  const _ProjectHistoryBody({required this.groupName});

  /// そのプロジェクトのタスクの学習セッションを、日付ごとの合計秒数にまとめる。
  Map<DateTime, int> _dailySeconds(AppState state) {
    final map = <DateTime, int>{};
    for (final t in state.tasks.where((t) => t.group == groupName)) {
      for (final s in t.sessions) {
        final day = startOfDay(s.date);
        map[day] = (map[day] ?? 0) + s.durationSeconds;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final g = state.groupProjectByName(groupName);
    final tasks = state.tasks.where((t) => t.group == groupName).toList();
    final daily = _dailySeconds(state);

    final totalMin = (tasks.fold<int>(0, (s, t) => s + t.timeSpent) / 60).round();
    final done = tasks.where((t) => t.completed).length;
    final pct = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();

    // カレンダーで表示する期間：プロジェクトに期間が設定されていればそれを、
    // 無ければ実際に記録がある日の範囲（無ければ今月）を使う。
    DateTime rangeStart;
    DateTime rangeEnd;
    if (g != null && g.startDate != null) {
      rangeStart = startOfDay(g.startDate!);
    } else if (daily.isNotEmpty) {
      rangeStart = daily.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    } else if (tasks.isNotEmpty) {
      rangeStart = startOfDay(tasks.map((t) => t.due).reduce((a, b) => a.isBefore(b) ? a : b));
    } else {
      rangeStart = startOfMonth(DateTime.now());
    }
    if (g != null && g.endDate != null) {
      rangeEnd = startOfDay(g.endDate!);
    } else if (daily.isNotEmpty) {
      rangeEnd = daily.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    } else if (tasks.isNotEmpty) {
      rangeEnd = startOfDay(tasks.map((t) => t.due).reduce((a, b) => a.isAfter(b) ? a : b));
    } else {
      rangeEnd = DateTime.now();
    }
    if (rangeEnd.isBefore(rangeStart)) rangeEnd = rangeStart;

    String periodText = '期間は設定されていません';
    if (g != null && g.hasPeriod) {
      String fmt(DateTime d) => '${d.year}/${d.month}/${d.day}';
      if (g.startDate != null && g.endDate != null) {
        periodText = '${fmt(g.startDate!)} 〜 ${fmt(g.endDate!)}';
      } else if (g.startDate != null) {
        periodText = '${fmt(g.startDate!)} 〜';
      } else {
        periodText = '〜 ${fmt(g.endDate!)}';
      }
    }

    final months = _monthsBetween(rangeStart, rangeEnd);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.event_repeat_rounded, size: 15, color: g?.isPast == true ? AppColors.inkFaint : AppColors.coral),
            const SizedBox(width: 6),
            Text(periodText, style: AppTheme.body(12.5, weight: FontWeight.w700, color: g?.isPast == true ? AppColors.inkFaint : AppColors.coral)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _statCard('学習時間', '$totalMin分')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('タスク数', '${tasks.length}件')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('完了率', '$pct%')),
          ]),
          const SizedBox(height: 20),
          Text('1日ごとの学習時間', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text('色が濃いほど、その日に長く勉強したことを表します', style: AppTheme.body(10.5, color: AppColors.inkFaint)),
          const SizedBox(height: 10),
          for (final m in months) _monthCalendar(m, daily),
          const SizedBox(height: 4),
          _legend(),
        ]),
      ),
    );
  }

  List<DateTime> _monthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var cur = DateTime(start.year, start.month, 1);
    final last = DateTime(end.year, end.month, 1);
    while (!cur.isAfter(last)) {
      months.add(cur);
      cur = DateTime(cur.year, cur.month + 1, 1);
      if (months.length > 12) break; // 安全のための上限
    }
    return months;
  }

  Widget _monthCalendar(DateTime month, Map<DateTime, int> daily) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7; // 0=日
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final seconds = daily[date] ?? 0;
      final minutes = (seconds / 60).round();
      cells.add(_dayCell(d, minutes));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${month.year}年${month.month}月', style: AppTheme.display(14)),
          const SizedBox(height: 8),
          Row(
            children: weekdaysJp
                .map((w) => Expanded(child: Center(child: Text(w, style: AppTheme.body(9.5, weight: FontWeight.w700, color: AppColors.inkFaint)))))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
            childAspectRatio: 0.95,
            children: cells,
          ),
        ]),
      ),
    );
  }

  Widget _dayCell(int day, int minutes) {
    final level = _intensityLevel(minutes);
    final bg = _levelColor(level);
    final textColor = level >= 3 ? Colors.white : AppColors.ink;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Text('$day', style: AppTheme.body(11, weight: FontWeight.w700, color: textColor)),
        if (minutes > 0)
          Text('$minutes分', style: AppTheme.mono(8, weight: FontWeight.w700, color: textColor)),
      ]),
    );
  }

  int _intensityLevel(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes < 30) return 1;
    if (minutes < 60) return 2;
    if (minutes < 120) return 3;
    return 4;
  }

  Color _levelColor(int level) {
    switch (level) {
      case 0:
        return AppColors.surface2;
      case 1:
        return AppColors.coralSoft;
      case 2:
        return AppColors.coral.withOpacity(.45);
      case 3:
        return AppColors.coral.withOpacity(.75);
      default:
        return AppColors.coral;
    }
  }

  Widget _legend() {
    return Row(children: [
      Text('少ない', style: AppTheme.body(10, color: AppColors.inkFaint)),
      const SizedBox(width: 6),
      ...List.generate(5, (i) => Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: _levelColor(i), borderRadius: BorderRadius.circular(4)),
          )),
      const SizedBox(width: 6),
      Text('多い', style: AppTheme.body(10, color: AppColors.inkFaint)),
    ]);
  }

  Widget _statCard(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.mono(15, color: AppColors.ink)),
        ]),
      );
}
