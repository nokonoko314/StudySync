import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
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

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = startOfMonth(DateTime.now());
  DateTime _selected = startOfDay(DateTime.now());

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta, 1));

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
                child: Container(width: 38, height: 38, decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle), child: const Icon(Icons.chevron_left, color: AppColors.ink)),
              ),
              Text('${_month.year}年${_month.month}月', style: AppTheme.display(16)),
              Pressable(
                onTap: () => _shift(1),
                child: Container(width: 38, height: 38, decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle), child: const Icon(Icons.chevron_right, color: AppColors.ink)),
              ),
            ]),
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
                // 選択中の日はセルの背景がインディゴになるため、通常タスクの
                // インディゴ色のドットが同化して見えなくなってしまう。
                // 選択中だけ、ドットに白い輪をつけてコントラストを確保する。
                final dots = dayTasks.map((t) {
                  final color = state.projectById(t.projectId)?.color ?? AppColors.inkFaint;
                  return Container(
                    width: 4.2,
                    height: 4.2,
                    margin: const EdgeInsets.all(0.8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 0.9) : null,
                    ),
                  );
                }).toList();
                return Pressable(
                  onTap: () => setState(() => _selected = startOfDay(c.date)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.indigo : (isToday ? AppColors.indigoSoft : Colors.transparent),
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
                              : (c.muted ? AppColors.inkFaint.withOpacity(.5) : (isToday ? AppColors.indigo : AppColors.ink)),
                        ),
                      ),
                      if (dots.isNotEmpty) const SizedBox(height: 3),
                      if (dots.isNotEmpty)
                        Wrap(alignment: WrapAlignment.center, runSpacing: 1.5, children: dots),
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
            if (agenda.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(children: [
                  const Icon(Icons.event_note_outlined, size: 40, color: AppColors.inkFaint),
                  const SizedBox(height: 10),
                  Text('この日に予定されているタスクはありません', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
                ]),
              )
            else
              ...agenda.map((t) => TaskCard(
                    task: t,
                    project: state.projectById(t.projectId),
                    onTap: () => showTaskDetailSheet(context, t.id),
                    onToggle: () => state.toggleComplete(t.id),
                    onTimer: () => showTimerSheet(context, t.id),
                  )),
          ],
        ),
      ),
    ]);
  }

  String _agendaLabel(DateTime d) {
    final base = '${d.month}月${d.day}日(${weekdayJp(d)})';
    return sameDay(d, DateTime.now()) ? '$base・今日' : base;
  }
}
