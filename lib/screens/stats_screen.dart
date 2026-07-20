import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/stats_charts.dart';
import '../widgets/pressable.dart';

enum _StatsView { summary, day, week, project, group }

class _Segment {
  final DateTime start;
  final DateTime end;
  final Project? project;
  final String taskTitle;
  final String taskId;
  final String sessionId;
  _Segment({
    required this.start,
    required this.end,
    required this.project,
    required this.taskTitle,
    required this.taskId,
    required this.sessionId,
  });
}

/// タイムライン表示用：同じ時間帯に重なるセッションを横に並べるための
/// レイアウト情報（何列目に置くか／その重なりグループの列数）。
class _LaidOutSegment {
  final _Segment seg;
  final int col;
  final int totalCols;
  _LaidOutSegment(this.seg, this.col, this.totalCols);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsView _view = _StatsView.day;
  DateTime _timelineDate = startOfDay(DateTime.now());

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

  /// 選択中の日に計測されたセッションを、その日の中の開始・終了時刻付きの
  /// 「区間」のリストにする。セッションは「終了時刻（date）」と「所要時間」
  /// だけを持っているので、開始時刻を end - duration として逆算し、
  /// 選択中の日の範囲（00:00〜24:00）にクリップする。
  List<_Segment> _daySegments(AppState state, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final segments = <_Segment>[];
    for (final t in state.tasks) {
      final project = state.projectById(t.projectId);
      for (final s in t.sessions) {
        final end = s.date;
        final start = end.subtract(Duration(seconds: s.durationSeconds));
        if (end.isBefore(dayStart) || start.isAfter(dayEnd)) continue;
        final clippedStart = start.isBefore(dayStart) ? dayStart : start;
        final clippedEnd = end.isAfter(dayEnd) ? dayEnd : end;
        if (!clippedEnd.isAfter(clippedStart)) continue;
        segments.add(_Segment(
          start: clippedStart,
          end: clippedEnd,
          project: project,
          taskTitle: t.title,
          taskId: t.id,
          sessionId: s.id,
        ));
      }
    }
    segments.sort((a, b) => a.start.compareTo(b.start));
    return segments;
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
        if (_view == _StatsView.summary) Text('学習時間のまとめ', style: AppTheme.body(12, color: AppColors.inkSoft)),
        const SizedBox(height: 14),
        if (_view == _StatsView.summary) ...[
          if (state.settings.weeklyGoalMinutes > 0) ...[
            _weeklyGoalCard(state, weekMin),
            const SizedBox(height: 16),
          ],
          Row(children: [
            Expanded(child: _statCard('総学習時間', totalMin)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('今週', weekMin)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('1日平均', avgMin)),
          ]),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(99), boxShadow: AppColors.cardShadow),
          child: Row(
            children: _StatsView.values.map((v) {
              final active = _view == v;
              final label = switch (v) {
                _StatsView.summary => 'まとめ',
                _StatsView.day => '日別',
                _StatsView.week => '週別',
                _StatsView.project => '教科別',
                _StatsView.group => 'プロジェクト別',
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
        if (_view == _StatsView.summary)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('直近7日間の学習時間', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: _buildChart(state),
        ),
        if (_view == _StatsView.summary) ...[
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
          const SizedBox(height: 22),
          Text('先週の振り返り', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          _weeklyRecapCard(state),
        ],
      ],
    );
  }

  /// 案A：週の目標時間に対する進み具合をリングで見せるカード。
  Widget _weeklyGoalCard(AppState state, int weekMin) {
    final goal = state.settings.weeklyGoalMinutes;
    final ratio = goal == 0 ? 0.0 : (weekMin / goal).clamp(0.0, 1.0);
    final remaining = (goal - weekMin).clamp(0, goal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Row(children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 6,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation(AppColors.indigo),
              ),
            ),
            Text('${(ratio * 100).round()}%', style: AppTheme.mono(12, color: AppColors.ink)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('今週の目標', style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 2),
            Text('${formatMinutes(weekMin)} / ${formatMinutes(goal)}', style: AppTheme.mono(15, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(
              remaining <= 0 ? '目標を達成しました' : '残り${formatMinutes(remaining)}で達成',
              style: AppTheme.body(10.5, color: AppColors.inkFaint),
            ),
          ]),
        ),
      ]),
    );
  }

  /// 案D：先週（直近に終わった週）の振り返りレポート。
  Widget _weeklyRecapCard(AppState state) {
    final today = startOfDay(DateTime.now());
    final thisMonday = today.subtract(Duration(days: (today.weekday + 6) % 7));
    final lastWeekStart = thisMonday.subtract(const Duration(days: 7));
    final lastWeekEnd = thisMonday;
    final prevWeekStart = lastWeekStart.subtract(const Duration(days: 7));

    int totalFor(DateTime start, DateTime end) {
      var total = 0;
      for (final t in state.tasks) {
        for (final s in t.sessions) {
          if (!s.date.isBefore(start) && s.date.isBefore(end)) total += s.durationSeconds;
        }
      }
      return total;
    }

    final lastWeekSec = totalFor(lastWeekStart, lastWeekEnd);
    final prevWeekSec = totalFor(prevWeekStart, lastWeekStart);
    final diffMin = ((lastWeekSec - prevWeekSec) / 60).round();

    final byProjectSec = <Project?, int>{};
    for (final t in state.tasks) {
      final p = state.projectById(t.projectId);
      for (final s in t.sessions) {
        if (!s.date.isBefore(lastWeekStart) && s.date.isBefore(lastWeekEnd)) {
          byProjectSec[p] = (byProjectSec[p] ?? 0) + s.durationSeconds;
        }
      }
    }
    final topEntry = byProjectSec.entries.isEmpty
        ? null
        : (byProjectSec.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    final completedInWeek = state.tasks.where((t) {
      final at = t.completedAt;
      return at != null && !at.isBefore(lastWeekStart) && at.isBefore(lastWeekEnd);
    }).length;

    final dayTotals = List.generate(7, (i) {
      final day = lastWeekStart.add(Duration(days: i));
      var total = 0;
      for (final t in state.tasks) {
        for (final s in t.sessions) {
          if (sameDay(s.date, day)) total += s.durationSeconds;
        }
      }
      return total;
    });
    final maxDay = dayTotals.fold<int>(1, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${lastWeekStart.month}/${lastWeekStart.day} 〜 ${lastWeekEnd.subtract(const Duration(days: 1)).month}/${lastWeekEnd.subtract(const Duration(days: 1)).day}',
            style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
        const SizedBox(height: 2),
        Text(formatMinutes((lastWeekSec / 60).round()), style: AppTheme.mono(20, color: AppColors.ink)),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dayTotals.map((sec) {
              final h = (sec / maxDay * 44).clamp(3, 44).toDouble();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(height: h, decoration: BoxDecoration(color: AppColors.indigo, borderRadius: BorderRadius.circular(3))),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _recapStatRow('先週との差', '${diffMin >= 0 ? '+' : ''}${formatMinutes(diffMin.abs())}', valueColor: diffMin >= 0 ? AppColors.sage : AppColors.coral),
        _recapStatRow(
          '一番学習した教科',
          topEntry == null ? '記録なし' : '${topEntry.key?.name ?? '教科なし'}（${formatMinutes((topEntry.value / 60).round())}）',
        ),
        _recapStatRow('完了したタスク', '$completedInWeek件', isLast: true),
      ]),
    );
  }

  Widget _recapStatRow(String label, String value, {Color? valueColor, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTheme.body(12, color: AppColors.inkSoft)),
        Text(value, style: AppTheme.mono(12, color: valueColor ?? AppColors.ink)),
      ]),
    );
  }

  Widget _buildChart(AppState state) {
    switch (_view) {
      case _StatsView.summary:
        return BarChartWidget(data: _daily(state, 7));
      case _StatsView.day:
        return _dayTimelineView(state);
      case _StatsView.week:
        return BarChartWidget(data: _weekly(state, 6));
      case _StatsView.project:
        return HorizontalBarList(items: _byProject(state));
      case _StatsView.group:
        return HorizontalBarList(items: _byGroup(state));
    }
  }

  /// 「日別」タブの中身：00:00〜24:00を1時間ごとの目盛りで表示し、
  /// 何時に何を勉強していたかを一目で見られるタイムライン表示。
  /// 同じ時間帯に重なっているセッションを検出し、横に並べて表示できるよう
  /// 列（column）を割り当てる。重なっているもの同士をひとまとまり（クラスタ）
  /// にし、クラスタの中で貪欲法により列を決める（カレンダーアプリの
  /// 日表示でよく使われる方法）。
  List<_LaidOutSegment> _layoutSegments(List<_Segment> segments) {
    final sorted = [...segments]..sort((a, b) => a.start.compareTo(b.start));
    final result = <_LaidOutSegment>[];

    List<_Segment> cluster = [];
    DateTime? clusterEnd;

    void flushCluster() {
      if (cluster.isEmpty) return;
      final columnsEnd = <DateTime>[];
      final colOf = <_Segment, int>{};
      for (final s in cluster) {
        var placed = -1;
        for (var c = 0; c < columnsEnd.length; c++) {
          if (!s.start.isBefore(columnsEnd[c])) {
            placed = c;
            break;
          }
        }
        if (placed == -1) {
          placed = columnsEnd.length;
          columnsEnd.add(s.end);
        } else {
          columnsEnd[placed] = s.end;
        }
        colOf[s] = placed;
      }
      final totalCols = columnsEnd.length;
      for (final s in cluster) {
        result.add(_LaidOutSegment(s, colOf[s]!, totalCols));
      }
      cluster = [];
      clusterEnd = null;
    }

    for (final s in sorted) {
      if (cluster.isEmpty || s.start.isBefore(clusterEnd!)) {
        cluster.add(s);
        if (clusterEnd == null || s.end.isAfter(clusterEnd!)) clusterEnd = s.end;
      } else {
        flushCluster();
        cluster.add(s);
        clusterEnd = s.end;
      }
    }
    flushCluster();
    return result;
  }

  Widget _dayTimelineView(AppState state) {
    final segments = _daySegments(state, _timelineDate);
    const labelWidth = 42.0;
    final interval = state.settings.timelineIntervalMinutes; // 30 or 60
    final pxPerMinute = interval == 30 ? 1.05 : 0.62; // 30分刻みのときは間隔を広げて見やすくする
    final totalHeight = 24 * 60 * pxPerMinute;
    final rowCount = (24 * 60) ~/ interval;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Pressable(
            onTap: () => setState(() => _timelineDate = _timelineDate.subtract(const Duration(days: 1))),
            child: Icon(Icons.chevron_left, color: AppColors.inkSoft),
          ),
          Column(children: [
            Text(formatJPDate(_timelineDate), style: AppTheme.body(13, weight: FontWeight.w700)),
            if (sameDay(_timelineDate, DateTime.now())) Text('今日', style: AppTheme.body(10, color: AppColors.inkFaint)),
          ]),
          Pressable(
            onTap: () => setState(() => _timelineDate = _timelineDate.add(const Duration(days: 1))),
            child: Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ),
        ]),
        const SizedBox(height: 8),
        if (segments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: Text('この日の学習記録はありません', style: AppTheme.body(12.5, color: AppColors.inkFaint))),
          ),
        SizedBox(
          height: totalHeight,
          child: LayoutBuilder(builder: (context, constraints) {
            final laidOut = _layoutSegments(segments);
            return Stack(children: [
              // 目盛り線とラベル（30分または60分ごと）
              for (var i = 0; i < rowCount; i++)
                Positioned(
                  top: i * interval * pxPerMinute,
                  left: 0,
                  right: 0,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: labelWidth,
                      child: Transform.translate(
                        offset: const Offset(0, -6),
                        child: Text(
                          '${pad2((i * interval) ~/ 60)}:${pad2((i * interval) % 60)}',
                          style: AppTheme.mono(9, weight: FontWeight.w700, color: AppColors.inkFaint),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: (i * interval) % 60 == 0 ? AppColors.line : AppColors.line.withOpacity(.45)),
                    ),
                  ]),
                ),
              // 学習セッションのブロック（重なる場合は横に並べる）
              for (final item in laidOut) _segmentBlock(item, _timelineDate, labelWidth, pxPerMinute, constraints.maxWidth),
            ]);
          }),
        ),
      ],
    );
  }

  Widget _segmentBlock(_LaidOutSegment item, DateTime day, double labelWidth, double pxPerMinute, double maxWidth) {
    final seg = item.seg;
    final dayStart = DateTime(day.year, day.month, day.day);
    final startMin = seg.start.difference(dayStart).inMinutes.clamp(0, 24 * 60).toDouble();
    final endMin = seg.end.difference(dayStart).inMinutes.clamp(0, 24 * 60).toDouble();
    final top = startMin * pxPerMinute;
    final height = ((endMin - startMin) * pxPerMinute).clamp(10.0, double.infinity).toDouble();
    final color = seg.project?.color ?? AppColors.inkFaint;

    // 重なっているセッションがある場合は、列数に応じて横幅を分割する。
    const rightPad = 4.0;
    const gap = 3.0;
    final trackLeft = labelWidth + 6;
    final trackWidth = (maxWidth - trackLeft - rightPad).clamp(0.0, double.infinity);
    final colWidth = item.totalCols > 0 ? (trackWidth - gap * (item.totalCols - 1)) / item.totalCols : trackWidth;
    final left = trackLeft + item.col * (colWidth + gap);
    final showText = height >= 16 && colWidth >= 40;

    return Positioned(
      top: top,
      left: left,
      width: colWidth.clamp(0.0, double.infinity),
      height: height,
      child: Pressable(
        onTap: () => _editSessionDialog(seg),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: showText ? 8 : 3, vertical: showText ? 2 : 0),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: color.withOpacity(.85),
            borderRadius: BorderRadius.circular(7),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: showText
              ? Text(
                  '${seg.project?.name ?? '教科なし'} ・ ${seg.taskTitle}',
                  maxLines: height >= 30 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(10.5, weight: FontWeight.w700, color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }

  /// 記録ミスの修正用ダイアログ。開始・終了時刻をその場で編集できる。
  Future<void> _editSessionDialog(_Segment seg) async {
    final state = context.read<AppState>();
    final task = state.taskById(seg.taskId);
    if (task == null) return;
    final session = task.sessions.firstWhere((s) => s.id == seg.sessionId, orElse: () => StudySession(id: '', date: DateTime.now(), durationSeconds: 0));
    if (session.id.isEmpty) return;
    // クリップ後の値ではなく、実際のセッションの開始・終了時刻を使う
    // （日をまたいでいた場合でも正しく編集できるように）。
    var start = session.date.subtract(Duration(seconds: session.durationSeconds));
    var end = session.date;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pick(bool isStart) async {
            final base = isStart ? start : end;
            final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(base));
            if (picked == null) return;
            setDialogState(() {
              final newTime = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
              if (isStart) {
                start = newTime;
              } else {
                end = newTime;
              }
            });
          }

          final valid = end.isAfter(start);
          return AlertDialog(
            title: const Text('記録を修正'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: AppTheme.body(12.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pick(true),
                    child: Column(children: [
                      Text('開始', style: AppTheme.body(10.5, color: AppColors.inkFaint)),
                      Text('${pad2(start.hour)}:${pad2(start.minute)}', style: AppTheme.mono(16)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pick(false),
                    child: Column(children: [
                      Text('終了', style: AppTheme.body(10.5, color: AppColors.inkFaint)),
                      Text('${pad2(end.hour)}:${pad2(end.minute)}', style: AppTheme.mono(16)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                valid ? '合計 ${formatDuration(end.difference(start).inSeconds)}' : '終了は開始より後にしてください',
                style: AppTheme.body(12, weight: FontWeight.w700, color: valid ? AppColors.inkSoft : AppColors.coral),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: const Text('削除', style: TextStyle(color: AppColors.coral)),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
              TextButton(
                onPressed: valid ? () => Navigator.pop(ctx, 'save') : null,
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );

    if (result == 'save') {
      state.editSession(seg.taskId, seg.sessionId, newStart: start, newEnd: end);
    } else if (result == 'delete') {
      state.deleteSession(seg.taskId, seg.sessionId);
    }
  }

  Widget _statCard(String label, int minutes) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(formatMinutes(minutes), style: AppTheme.mono(18, color: AppColors.ink)),
        ]),
      );
}
