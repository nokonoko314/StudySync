import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/task.dart';
import '../app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/pressable.dart';
import '../widgets/project_drawer.dart';
import '../widgets/live_clock.dart';
import '../sheets/add_edit_task_sheet.dart';
import '../sheets/task_detail_sheet.dart';
import '../sheets/timer_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final project = state.projectById(state.activeProjectId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const ProjectDrawer(),
      body: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 18, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Builder(
                builder: (ctx) => Pressable(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project?.name ?? 'すべてのタスク', style: AppTheme.display(21)),
                  Text(
                    project != null ? 'この教科のタスクを表示中' : '登録中のタスクと教科',
                    style: AppTheme.body(12, color: AppColors.inkSoft),
                  ),
                  if (project != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Pressable(
                        onTap: () => state.setActiveProject(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(99)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(project.name, style: AppTheme.body(11.5, weight: FontWeight.w700, color: AppColors.indigo)),
                            const SizedBox(width: 6),
                            const Icon(Icons.close, size: 11, color: AppColors.indigo),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              const Padding(padding: EdgeInsets.only(top: 2), child: LiveClock()),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _StatusSegmented(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
              children: _buildGroupedList(context, state),
            ),
          ),
        ]),
        Positioned(
          right: 20,
          bottom: 20,
          child: Pressable(
            onTap: () => showAddEditTaskSheet(context, projectIdHint: state.activeProjectId),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.indigo,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.indigo.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context, AppState state) {
    final list = state.filteredTasks;
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(children: [
            const Icon(Icons.auto_graph_rounded, size: 54, color: AppColors.inkFaint),
            const SizedBox(height: 14),
            Text('タスクがありません', style: AppTheme.display(16)),
            const SizedBox(height: 4),
            Text('右下の + から新しいタスクを追加しましょう', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
          ]),
        ),
      ];
    }

    if (state.statusFilter == StatusFilter.byDeadline) {
      // 締切が近い順：科目で分けず、フラットに期限の近い順で並べる
      final sorted = [...list]..sort((a, b) => a.due.compareTo(b.due));
      return sorted
          .map((t) => TaskCard(
                task: t,
                project: state.projectById(t.projectId),
                onTap: () => showTaskDetailSheet(context, t.id),
                onToggle: () => state.toggleComplete(t.id),
                onTimer: () => showTimerSheet(context, t.id),
              ))
          .toList();
    }

    final Map<String, List<Task>> groups = {};
    final order = <String>[];
    for (final t in list) {
      final key = t.group ?? '未分類';
      groups.putIfAbsent(key, () {
        order.add(key);
        return [];
      }).add(t);
    }
    order.sort((a, b) {
      if (a == '未分類') return 1;
      if (b == '未分類') return -1;
      final am = groups[a]!.map((t) => t.due).reduce((x, y) => x.isBefore(y) ? x : y);
      final bm = groups[b]!.map((t) => t.due).reduce((x, y) => x.isBefore(y) ? x : y);
      return am.compareTo(bm);
    });

    final widgets = <Widget>[];
    for (final key in order) {
      final arr = groups[key]!..sort((a, b) => a.due.compareTo(b.due));
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8, left: 2, right: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(key, style: AppTheme.display(15)),
          const SizedBox(width: 8),
          Text('${arr.length}件', style: AppTheme.body(11.5, weight: FontWeight.w600, color: AppColors.inkFaint)),
        ]),
      ));
      for (final t in arr) {
        widgets.add(TaskCard(
          task: t,
          project: state.projectById(t.projectId),
          onTap: () => showTaskDetailSheet(context, t.id),
          onToggle: () => state.toggleComplete(t.id),
          onTimer: () => showTimerSheet(context, t.id),
        ));
      }
    }
    return widgets;
  }
}

class _StatusSegmented extends StatelessWidget {
  const _StatusSegmented();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(99), boxShadow: AppColors.cardShadow),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: StatusFilter.values.map((f) {
            final active = state.statusFilter == f;
            return Pressable(
              onTap: () => state.setStatusFilter(f),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: active ? AppColors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                child: Text(f.label, style: AppTheme.body(12.5, weight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
