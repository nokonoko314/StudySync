import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/stats_charts.dart';

enum _StatsView { day, week, project, group, task }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsView _view = _StatsView.day;

  List<ChartPoint> _daily(AppState state, int daysBack) {
    final out = <ChartPoint>[];
    for (var i = daysBack - 1; i >= 0; i--) {
      final day = startOfDay(DateTime.now().subtract(Duration(days: i)));
      var total = 0;
      for (final t in state.tasks) {
        for (final s in t.sessions) {
          if (sameDay(s.date, day)) total += s.durationSeconds;
        }
      }
      out.add(ChartPoint(weekdayJp(day), (total / 60).round()));
    }
    return out;
  }

  List<ChartPoint> _weekly(AppState state, int weeksBack) {
    final out = <ChartPoint>[];
    final today = startOfDay(DateTime.now());
    final thisMonday = today.subtract(Duration(days: (today.weekday + 6) % 7));
    for (var w = weeksBack - 1; w >= 0; w--) {
      final weekStart = thisMonday.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      var total = 0;
      for (final t in state.tasks) {
        for (final s in t.sessions) {
          if (!s.date.isBefore(weekStart) && s.date.isBefore(weekEnd)) total += s.durationSeconds;
        }
      }
      out.add(ChartPoint('${weekStart.month}/${weekStart.day}週', (total / 60).round()));
    }
    return out;
  }

  List<HBarItem> _byProject(AppState state) {
    final items = state.projects.map((p) {
      final total = state.tasks.where((t) => t.projectId == p.id).fold<int>(0, (s, t) => s + t.timeSpent);
      return HBarItem(p.name, p.color, (total / 60).round());
    }).toList();
    items.sort((a, b) => b.minutes.compareTo(a.minutes));
    return items;
  }

  List<HBarItem> _byGroup(AppState state) {
    final groups = state.settings.knownGroups;
    final items = groups.map((g) {
      final total = state.tasks.where((t) => t.group == g.name).fold<int>(0, (s, t) => s + t.timeSpent);
      return HBarItem(g.name, AppColors.coral, (total / 60).round());
    }).toList();
    final untaggedTotal = state.tasks.where((t) => t.group == null).fold<int>(0, (s, t) => s + t.timeSpent);
    if (untaggedTotal > 0) {
      items.add(HBarItem('未分類', AppColors.inkFaint, (untaggedTotal / 60).round()));
    }
    items.sort((a, b) => b.minutes.compareTo(a.minutes));
    return items;
  }

  List<HBarItem> _byTask(AppState state) {
    final items = state.tasks.where((t) => t.timeSpent > 0).map((t) {
      final p = state.projectById(t.projectId);
      return HBarItem(t.title, p?.color ?? AppColors.inkFaint, (t.timeSpent / 60).round());
    }).toList();
    items.sort((a, b) => b.minutes.compareTo(a.minutes));
    return items.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final totalMin = (state.tasks.fold<int>(0, (s, t) => s + t.timeSpent) / 60).round();
    final weekMin = _daily(state, 7).fold<int>(0, (s, d) => s + d.value);
    final avgMin = (weekMin / 7).round();
    final total = state.tasks.length;
    final done = state.tasks.where((t) => t.completed).length;
    final pct = total == 0 ? 0 : (done / total * 100).round();
    final overdueCount = state.tasks.where((t) => t.isOverdue).length;
    final reviewCount = state.tasks.where((t) => t.isReview).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: [
        Text('学習統計', style: AppTheme.display(21)),
        Text('いろいろな角度から学習時間を見る', style: AppTheme.body(12, color: AppColors.inkSoft)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _statCard('総学習時間', totalMin)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('今週', weekMin)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('1日平均', avgMin)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(99), boxShadow: AppColors.cardShadow),
          child: Row(
            children: _StatsView.values.map((v) {
              final active = _view == v;
              final label = switch (v) {
                _StatsView.day => '日別',
                _StatsView.week => '週別',
                _StatsView.project => '教科別',
                _StatsView.group => 'プロジェクト別',
                _StatsView.task => 'タスク別',
              };
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _view = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: active ? AppColors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                    child: Center(child: Text(label, style: AppTheme.body(12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: _buildChart(state),
        ),
        const SizedBox(height: 22),
        Text('完了率', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(children: [
            CompletionDonut(percent: pct),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: '完了タスク：', style: AppTheme.body(12, color: AppColors.inkSoft)),
                  TextSpan(text: '$done', style: AppTheme.mono(12, color: AppColors.ink)),
                  TextSpan(text: ' / 全体：', style: AppTheme.body(12, color: AppColors.inkSoft)),
                  TextSpan(text: '$total', style: AppTheme.mono(12, color: AppColors.ink)),
                ])),
                const SizedBox(height: 4),
                Text('期限切れ：$overdueCount件', style: AppTheme.body(12, color: AppColors.inkSoft)),
                const SizedBox(height: 4),
                Text('復習タスク：$reviewCount件', style: AppTheme.body(12, color: AppColors.inkSoft)),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildChart(AppState state) {
    switch (_view) {
      case _StatsView.day:
        return BarChartWidget(data: _daily(state, 7));
      case _StatsView.week:
        return BarChartWidget(data: _weekly(state, 6));
      case _StatsView.project:
        return HorizontalBarList(items: _byProject(state));
      case _StatsView.group:
        return HorizontalBarList(items: _byGroup(state));
      case _StatsView.task:
        return HorizontalBarList(items: _byTask(state));
    }
  }

  Widget _statCard(String label, int minutes) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            TextSpan(text: '$minutes', style: AppTheme.mono(18, color: AppColors.ink)),
            TextSpan(text: '分', style: AppTheme.body(11, color: AppColors.inkSoft)),
          ])),
        ]),
      );
}
