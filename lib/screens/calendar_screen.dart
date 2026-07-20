import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/task_card.dart';
import '../widgets/pressable.dart';
import '../sheets/task_detail_sheet.dart';
import '../sheets/timer_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalCell {
  final int day;
  final bool muted;
  final DateTime date;
  _CalCell(this.day, this.muted, this.date);
}

enum _ViewMode { tasks, time }

class _SessionSpan {
  final String taskId;
  final String sessionId;
  final String taskTitle;
  final DateTime start;
  final DateTime end;
  final int durationSeconds;
  _SessionSpan({
    required this.taskId,
    required this.sessionId,
    required this.taskTitle,
    required this.start,
    required this.end,
    required this.durationSeconds,
  });
}

class _SubjectDayStats {
  int totalSeconds = 0;
  int sessionCount = 0;
  DateTime? earliest;
  DateTime? latest;
  final List<_SessionSpan> sessions = [];
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = startOfMonth(DateTime.now());
  DateTime _selected = startOfDay(DateTime.now());
  // 開閉状態を教科IDごとに覚えておく（無い教科は 'none' キー）。
  final Set<String> _collapsed = {};
  _ViewMode _viewMode = _ViewMode.tasks;

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

  void _toggleGroup(String key) => setState(() {
        if (_collapsed.contains(key)) {
          _collapsed.remove(key);
        } else {
          _collapsed.add(key);
        }
      });

  /// 日付ごとの合計学習時間（秒）。カレンダーを「時間」表示にしたときの
  /// オレンジの濃淡や、選択中の日の内訳に使う。
  Map<DateTime, int> _dailySeconds(AppState state) {
    final map = <DateTime, int>{};
    for (final t in state.tasks) {
      for (final s in t.sessions) {
        final day = startOfDay(s.date);
        map[day] = (map[day] ?? 0) + s.durationSeconds;
      }
    }
    return map;
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
        return Colors.transparent;
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7; // 0=日
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final daysInPrevMonth = DateTime(_month.year, _month.month, 0).day;

    final cells = <_CalCell>[];
    for (var i = firstWeekday - 1; i >= 0; i--) {
      cells.add(_CalCell(daysInPrevMonth - i, true, DateTime(_month.year, _month.month - 1, daysInPrevMonth - i)));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_CalCell(d, false, DateTime(_month.year, _month.month, d)));
    }
    final rem = (7 - cells.length % 7) % 7;
    for (var n = 1; n <= rem; n++) {
      cells.add(_CalCell(n, true, DateTime(_month.year, _month.month + 1, n)));
    }

    final agenda = state.tasks.where((t) => sameDay(t.due, _selected)).toList()..sort((a, b) => a.due.compareTo(b.due));
    final dailySecondsMap = _dailySeconds(state);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('カレンダー', style: AppTheme.display(21)),
          Text('タップした日の予定がすぐに見られます', style: AppTheme.body(12, color: AppColors.inkSoft)),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Pressable(
                onTap: () => _shift(-1),
                child: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle), child: Icon(Icons.chevron_left, color: AppColors.ink)),
              ),
              Text('${_month.year}年${_month.month}月', style: AppTheme.display(16)),
              Pressable(
                onTap: () => _shift(1),
                child: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle), child: Icon(Icons.chevron_right, color: AppColors.ink)),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(99), boxShadow: AppColors.cardShadow),
              child: Row(
                children: _ViewMode.values.map((v) {
                  final active = _viewMode == v;
                  final label = v == _ViewMode.tasks ? 'タスク' : '時間';
                  final icon = v == _ViewMode.tasks ? Icons.checklist_rounded : Icons.local_fire_department_rounded;
                  return Expanded(
                    child: Pressable(
                      onTap: () => setState(() => _viewMode = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: active ? AppColors.coral : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icon, size: 13, color: active ? Colors.white : AppColors.inkSoft),
                          const SizedBox(width: 5),
                          Text(label, style: AppTheme.body(12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: weekdaysJp
                  .map((w) => Expanded(child: Center(child: Text(w, style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.inkFaint)))))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              childAspectRatio: 0.8,
              children: cells.map((c) {
                final dayTasks = state.tasks.where((t) => sameDay(t.due, c.date)).toList();
                final isToday = sameDay(c.date, DateTime.now());
                final isSelected = sameDay(c.date, _selected);
                final daySeconds = dailySecondsMap[startOfDay(c.date)] ?? 0;
                final timeLevel = _intensityLevel((daySeconds / 60).round());
                // 選択中の日はセルの背景がインディゴになるため、通常タスクの
                // インディゴ色のドットが同化して見えなくなってしまう。
                // 選択中だけ、ドットに白い輪をつけてコントラストを確保する。
                // タスクが多い日でもセルの高さが崩れないよう、ドットは
                // 最大4個までにして、それ以上は「+N」のドットにまとめる。
                const maxDots = 5;
                final shown = dayTasks.length > maxDots ? maxDots - 1 : dayTasks.length;
                final dots = [
                  for (final t in dayTasks.take(shown))
                    Container(
                      width: 4.2,
                      height: 4.2,
                      margin: const EdgeInsets.all(0.8),
                      decoration: BoxDecoration(
                        color: state.projectById(t.projectId)?.color ?? AppColors.inkFaint,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 0.9) : null,
                      ),
                    ),
                  if (dayTasks.length > maxDots)
                    Container(
                      margin: const EdgeInsets.all(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      constraints: const BoxConstraints(minWidth: 4.2, minHeight: 4.2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.inkFaint,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+${dayTasks.length - shown}',
                        style: AppTheme.mono(6.5, weight: FontWeight.w800, color: isSelected ? AppColors.indigo : AppColors.surface),
                      ),
                    ),
                ];
                return Pressable(
                  onTap: () => setState(() => _selected = startOfDay(c.date)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.indigo
                          : (_viewMode == _ViewMode.time
                              ? _levelColor(timeLevel)
                              : (isToday ? AppColors.indigoSoft : Colors.transparent)),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        '${c.day}',
                        style: AppTheme.body(
                          12.5,
                          weight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (c.muted
                                  ? AppColors.inkFaint.withOpacity(.5)
                                  : (_viewMode == _ViewMode.time && timeLevel >= 3)
                                      ? Colors.white
                                      : (isToday ? AppColors.indigo : AppColors.ink)),
                        ),
                      ),
                      if (_viewMode == _ViewMode.tasks) ...[
                        if (dots.isNotEmpty) const SizedBox(height: 3),
                        if (dots.isNotEmpty)
                          Wrap(alignment: WrapAlignment.center, runSpacing: 1.5, children: dots),
                      ] else if (daySeconds > 0) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMinutes((daySeconds / 60).round()),
                              style: AppTheme.mono(7.5,
                                  weight: FontWeight.w800,
                                  color: isSelected ? Colors.white : (timeLevel >= 3 ? Colors.white : AppColors.coral)),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(_agendaLabel(_selected), style: AppTheme.display(15.5)),
              const SizedBox(width: 8),
              Text('${agenda.length}件', style: AppTheme.body(11.5, color: AppColors.inkFaint)),
            ]),
            const SizedBox(height: 8),
            if (_viewMode == _ViewMode.tasks) ...[
              if (agenda.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(children: [
                    Icon(Icons.event_note_outlined, size: 40, color: AppColors.inkFaint),
                    const SizedBox(height: 10),
                    Text('この日に予定されているタスクはありません', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
                  ]),
                )
              else
                ..._groupedBySubject(state, agenda).entries.expand((entry) {
                  final project = entry.key;
                  final tasksForProject = entry.value;
                  final key = project?.id ?? 'none';
                  final isCollapsed = _collapsed.contains(key);
                  final scale = state.settings.calendarAgendaScale;
                  return [
                    Pressable(
                      onTap: () => _toggleGroup(key),
                      child: Padding(
                        padding: EdgeInsets.only(top: 4 * scale, bottom: 6 * scale),
                        child: Row(children: [
                          Icon(isCollapsed ? Icons.chevron_right : Icons.expand_more, size: 16 * scale, color: AppColors.inkFaint),
                          SizedBox(width: 2 * scale),
                          Container(
                            width: 8 * scale,
                            height: 8 * scale,
                            decoration: BoxDecoration(color: project?.color ?? AppColors.inkFaint, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 7 * scale),
                          Text(project?.name ?? '教科なし', style: AppTheme.body(12.5 * scale, weight: FontWeight.w800, color: AppColors.inkSoft)),
                          SizedBox(width: 6 * scale),
                          Text('${tasksForProject.length}件', style: AppTheme.body(10.5 * scale, color: AppColors.inkFaint)),
                        ]),
                      ),
                    ),
                    if (!isCollapsed)
                      ...tasksForProject.map((t) => Padding(
                            padding: EdgeInsets.only(left: 15 * scale, bottom: 2 * scale),
                            child: TaskCard(
                              task: t,
                              project: state.projectById(t.projectId),
                              onTap: () => showTaskDetailSheet(context, t.id),
                              onToggle: () => state.toggleComplete(t.id),
                              onTimer: () => showTimerSheet(context, t.id),
                            ),
                          )),
                    SizedBox(height: 10 * scale),
                  ];
                }),
            ] else ...[
              // 「時間」モード：その日に計測した学習時間を教科ごとに表示する。
              // 今日はまだ進行中なのでシンプルな一覧、過去の日は
              // 「振り返りカード」としてまとめて見せる（案②）。
              Builder(builder: (context) {
                final bySubject = _dailyStatsBySubject(state, _selected);
                final totalSec = bySubject.values.fold<int>(0, (s, v) => s + v.totalSeconds);
                if (totalSec <= 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(children: [
                      Icon(Icons.local_fire_department_outlined, size: 40, color: AppColors.inkFaint),
                      const SizedBox(height: 10),
                      Text('この日の学習記録はありません', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
                    ]),
                  );
                }
                final entries = bySubject.entries.toList()..sort((a, b) => b.value.totalSeconds.compareTo(a.value.totalSeconds));
                final isPast = _selected.isBefore(startOfDay(DateTime.now()));
                return isPast
                    ? _recapCard(state, entries, totalSec)
                    : _todayList(state, entries, totalSec);
              }),
            ],
          ],
        ),
      ),
    ]);
  }

  /// 選択中の日のタスクを、教科ごとにまとめる（教科の並び順に揃える）。
  /// 「｜＿タスク」のように、教科の下にそのタスクが小分けにぶら下がって
  /// 見えるようにするための下準備。
  Map<Project?, List<Task>> _groupedBySubject(AppState state, List<Task> tasks) {
    final grouped = <Project?, List<Task>>{};
    for (final p in state.projects) {
      final forProject = tasks.where((t) => t.projectId == p.id).toList();
      if (forProject.isNotEmpty) grouped[p] = forProject;
    }
    final noProject = tasks.where((t) => state.projectById(t.projectId) == null).toList();
    if (noProject.isNotEmpty) grouped[null] = noProject;
    return grouped;
  }

  /// 選択中の日の学習時間を、教科ごとにまとめる（「時間」モード用）。
  /// 合計時間だけでなく、セッション回数・最初と最後の時刻も持たせて、
  /// 単なる棒グラフより意味のある情報を表示できるようにする。
  Map<Project?, _SubjectDayStats> _dailyStatsBySubject(AppState state, DateTime day) {
    final map = <Project?, _SubjectDayStats>{};
    for (final t in state.tasks) {
      final project = state.projectById(t.projectId);
      for (final s in t.sessions) {
        if (!sameDay(s.date, day)) continue;
        final start = s.date.subtract(Duration(seconds: s.durationSeconds));
        final end = s.date;
        final stats = map.putIfAbsent(project, () => _SubjectDayStats());
        stats.totalSeconds += s.durationSeconds;
        stats.sessionCount += 1;
        if (stats.earliest == null || start.isBefore(stats.earliest!)) stats.earliest = start;
        if (stats.latest == null || end.isAfter(stats.latest!)) stats.latest = end;
        stats.sessions.add(_SessionSpan(
          taskId: t.id,
          sessionId: s.id,
          taskTitle: t.title,
          start: start,
          end: end,
          durationSeconds: s.durationSeconds,
        ));
      }
    }
    return map;
  }

  /// 今日（進行中の日）用：時間と割合だけのシンプルな一覧（案①）。
  Widget _todayList(AppState state, List<MapEntry<Project?, _SubjectDayStats>> entries, int totalSec) {
    final scale = state.settings.calendarAgendaScale;
    return Container(
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(13)),
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: 9 * scale),
              decoration: i == 0 ? null : BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: _subjectRow(entries[i].key, entries[i].value, totalSec, scale),
            ),
        ],
      ),
    );
  }

  /// 過去の日用：合計・一番集中した教科・積み上げバーをまとめた
  /// 「振り返りカード」（案②）。教科の行をタップすると、その日その教科の
  /// 個別セッション（開始〜終了・削除）を見られる。
  Widget _recapCard(AppState state, List<MapEntry<Project?, _SubjectDayStats>> entries, int totalSec) {
    final scale = state.settings.calendarAgendaScale;
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('この日の学習時間', style: AppTheme.body(11.5 * scale, weight: FontWeight.w700, color: AppColors.inkSoft)),
              Text(formatMinutes((totalSec / 60).round()), style: AppTheme.mono(22 * scale, color: AppColors.ink)),
            ]),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 4 * scale),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
            child: Text('${entries.length}教科', style: AppTheme.body(10.5 * scale, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
        ]),
        SizedBox(height: 14 * scale),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 12 * scale,
            child: Row(
              children: entries.map((e) {
                final color = e.key?.color ?? AppColors.inkFaint;
                final flexValue = (e.value.totalSeconds * 1000 / totalSec).round().clamp(1, 1000);
                return Expanded(flex: flexValue, child: Container(color: color));
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 6 * scale),
        for (final e in entries)
          Pressable(
            onTap: () => _showSubjectDetail(context, e.key, e.value),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6 * scale),
              child: _subjectRow(e.key, e.value, totalSec, scale, showChevron: true),
            ),
          ),
      ]),
    );
  }

  Widget _subjectRow(Project? project, _SubjectDayStats stats, int totalSec, double scale, {bool showChevron = false}) {
    final minutes = (stats.totalSeconds / 60).round();
    final pct = totalSec == 0 ? 0 : (stats.totalSeconds / totalSec * 100).round();
    final color = project?.color ?? AppColors.inkFaint;
    return Row(children: [
      Container(width: 8 * scale, height: 8 * scale, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: 8 * scale),
      Expanded(
        child: Text(project?.name ?? '教科なし', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(12.5 * scale, weight: FontWeight.w700)),
      ),
      Text(formatMinutes(minutes), style: AppTheme.mono(12 * scale, color: AppColors.ink)),
      SizedBox(width: 8 * scale),
      SizedBox(width: 30 * scale, child: Text('$pct%', textAlign: TextAlign.right, style: AppTheme.body(10.5 * scale, color: AppColors.inkFaint))),
      if (showChevron) ...[
        SizedBox(width: 2 * scale),
        Icon(Icons.chevron_right, size: 16 * scale, color: AppColors.inkFaint),
      ],
    ]);
  }

  /// 教科の行をタップしたときの詳細（その日その教科の個別セッション一覧）。
  void _showSubjectDetail(BuildContext context, Project? project, _SubjectDayStats stats) {
    final state = context.read<AppState>();
    final sessions = [...stats.sessions]..sort((a, b) => a.start.compareTo(b.start));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(project?.name ?? '教科なし'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final s in sessions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${pad2(s.start.hour)}:${pad2(s.start.minute)}〜${pad2(s.end.hour)}:${pad2(s.end.minute)}',
                        style: AppTheme.body(12.5, color: AppColors.inkSoft)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(formatDuration(s.durationSeconds), style: AppTheme.mono(12.5, weight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          state.deleteSession(s.taskId, s.sessionId);
                          sessions.removeWhere((x) => x.sessionId == s.sessionId);
                          setDialogState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 14, color: AppColors.inkFaint),
                        ),
                      ),
                    ]),
                  ]),
                ),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('記録がありません', style: AppTheme.body(12.5, color: AppColors.inkFaint)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
          ],
        ),
      ),
    );
  }

  String _agendaLabel(DateTime d) {
    final base = '${d.month}月${d.day}日(${weekdayJp(d)})';
    return sameDay(d, DateTime.now()) ? '$base・今日' : base;
  }
}
