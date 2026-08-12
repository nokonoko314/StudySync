import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/task_card.dart';
import '../widgets/pressable.dart';
import '../widgets/project_drawer.dart';
import '../widgets/live_clock.dart';
import '../sheets/add_edit_task_sheet.dart';
import '../sheets/task_detail_sheet.dart';
import '../sheets/timer_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final project = state.projectById(state.activeProjectId);
    final groupTag = state.activeGroupTag;
    final title = project?.name ?? groupTag ?? 'すべてのタスク';

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const ProjectDrawer(),
      floatingActionButton: Pressable(
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
      body: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_greeting(), style: AppTheme.body(12.5, color: AppColors.inkSoft))),
                Builder(
                  builder: (ctx) => Pressable(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
                      child: Icon(Icons.menu_rounded, size: 16, color: AppColors.ink),
                    ),
                  ),
                ),
              ]),
              const LiveClock(),
              const SizedBox(height: 2),
              Text('$_dateLabel・$title', style: AppTheme.body(12, color: AppColors.inkFaint)),
              if (project != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Pressable(
                    onTap: () => state.setActiveProject(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(project.name, style: AppTheme.body(11.5, weight: FontWeight.w700, color: AppColors.indigo)),
                        const SizedBox(width: 6),
                        Icon(Icons.close, size: 11, color: AppColors.indigo),
                      ]),
                    ),
                  ),
                )
              else if (groupTag != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Pressable(
                    onTap: () => state.setActiveGroupTag(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.coralSoft, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(groupTag, style: AppTheme.body(11.5, weight: FontWeight.w700, color: AppColors.coral)),
                        const SizedBox(width: 6),
                        const Icon(Icons.close, size: 11, color: AppColors.coral),
                      ]),
                    ),
                  ),
                ),
              _HomeGlanceRow(state: state),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _StatusSegmented(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.statusFilter == StatusFilter.byDeadline
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    children: _buildDeadlineList(context, state),
                  )
                : _ReorderableTaskList(state: state),
          ),
        ]),
      ]),
    );
  }

  List<Widget> _buildDeadlineList(BuildContext context, AppState state) {
    // 「締切が近い順」：科目で分けず、フラットに期限の近い順で並べる（自動ソート、並び替え不可）。
    final list = [...state.filteredTasks]..sort((a, b) => a.due.compareTo(b.due));
    if (list.isEmpty) {
      return [_emptyState()];
    }
    return [
      for (var i = 0; i < list.length; i++)
        _maybeWithHint(
          state,
          isFirst: i == 0,
          child: _SwipeableTaskCard(
            task: list[i],
            project: state.projectById(list[i].projectId),
            onTap: () => showTaskDetailSheet(context, list[i].id),
            onToggle: () => state.toggleComplete(list[i].id),
            onTimer: () => showTimerSheet(context, list[i].id),
            onDelete: () => _deleteWithUndo(context, state, list[i]),
          ),
        ),
    ];
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'こんばんは';
    if (h < 11) return 'おはようございます';
    if (h < 17) return 'こんにちは';
    return 'こんばんは';
  }

  String get _dateLabel {
    final now = DateTime.now();
    return '${now.month}/${now.day}(${weekdayJp(now)})';
  }
}

/// ホームヘッダー下部の一言：週間目標のミニリングと連続学習日数。
/// どちらも未設定/0日なら何も表示しない（情報過多を避ける）。
class _HomeGlanceRow extends StatelessWidget {
  final AppState state;
  const _HomeGlanceRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final goal = state.settings.weeklyGoalMinutes;
    final streak = state.currentStreakDays;
    if (goal <= 0 && streak <= 0) return const SizedBox.shrink();
    final ratio = goal <= 0 ? 0.0 : (state.weeklyStudyMinutes / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        if (goal > 0) ...[
          SizedBox(
            width: 22,
            height: 22,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                backgroundColor: AppColors.indigoSoft,
                valueColor: AlwaysStoppedAnimation(AppColors.indigo),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text('今週の目標 ${(ratio * 100).round()}%', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkSoft)),
        ],
        if (goal > 0 && streak > 0) const SizedBox(width: 14),
        if (streak > 0) ...[
          Icon(Icons.local_fire_department_rounded, size: 15, color: AppColors.gold),
          const SizedBox(width: 3),
          Text('$streak日連続で学習中', style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.gold)),
        ],
      ]),
    );
  }
}

Widget _maybeWithHint(AppState state, {required bool isFirst, required Widget child}) {
  if (!isFirst || state.settings.sawSwipeHint) return child;
  return _SwipeHintWrapper(child: child);
}

void _deleteWithUndo(BuildContext context, AppState state, Task t) {
  state.requestDeleteTask(t.id);
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('「${t.title}」を削除しました'),
    action: SnackBarAction(label: '元に戻す', textColor: Colors.white, onPressed: () => state.undoDeleteTask(t.id)),
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.ink,
  ));
}

/// 初回のみ、カードがそっと左右に動いてスワイプ操作を案内する。
/// 一度表示したら AppSettings.sawSwipeHint に記録し、以後は出さない。
class _SwipeHintWrapper extends StatefulWidget {
  final Widget child;
  const _SwipeHintWrapper({required this.child});

  @override
  State<_SwipeHintWrapper> createState() => _SwipeHintWrapperState();
}

class _SwipeHintWrapperState extends State<_SwipeHintWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 44).chain(CurveTween(curve: Curves.easeOut)), weight: 38),
      TweenSequenceItem(tween: Tween<double>(begin: 44, end: 0).chain(CurveTween(curve: Curves.easeInOut)), weight: 62),
    ]).animate(_ctrl);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        context.read<AppState>().markSwipeHintSeen();
      }
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: widget.child,
    );
  }
}

Widget _emptyState() => Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Icon(Icons.auto_graph_rounded, size: 54, color: AppColors.inkFaint),
        const SizedBox(height: 14),
        Text('タスクがありません', style: AppTheme.display(16)),
        const SizedBox(height: 4),
        Text('右下の + から新しいタスクを追加しましょう', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
      ]),
    );

/// 締切が近い順以外の全タブ：長押しハンドルでドラッグして並び替えられ、
/// 左右スワイプで完了・削除もできる一覧。
class _ReorderableTaskList extends StatelessWidget {
  final AppState state;
  const _ReorderableTaskList({required this.state});

  @override
  Widget build(BuildContext context) {
    final list = state.filteredTasks; // すでに sortOrder 順
    if (list.isEmpty) return _emptyState();
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      buildDefaultDragHandles: false,
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final ids = list.map((t) => t.id).toList();
        final id = ids.removeAt(oldIndex);
        ids.insert(newIndex, id);
        state.setTaskPriorityOrder(ids);
      },
      itemBuilder: (context, i) {
        final t = list[i];
        return Padding(
          key: ValueKey(t.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(
              child: _maybeWithHint(
                state,
                isFirst: i == 0,
                child: _SwipeableTaskCard(
                  task: t,
                  project: state.projectById(t.projectId),
                  onTap: () => showTaskDetailSheet(context, t.id),
                  onToggle: () => state.toggleComplete(t.id),
                  onTimer: () => showTimerSheet(context, t.id),
                  onDelete: () => _deleteWithUndo(context, state, t),
                ),
              ),
            ),
            const SizedBox(width: 2),
            ReorderableDragStartListener(
              index: i,
              child: Container(
                width: 40,
                height: 48,
                alignment: Alignment.center,
                child: Icon(Icons.drag_handle_rounded, size: 26, color: AppColors.inkFaint),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// タスクカードを左右スワイプでも操作できるようにするラッパー。
/// 右スワイプ＝完了切り替え、左スワイプ＝削除。どちらもカードは元の位置に
/// スナックバック（実際の表示/非表示は一覧の再構築に任せる）。
class _SwipeableTaskCard extends StatelessWidget {
  final Task task;
  final Project? project;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onTimer;
  final VoidCallback onDelete;

  const _SwipeableTaskCard({
    required this.task,
    required this.project,
    required this.onTap,
    required this.onToggle,
    required this.onTimer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('swipe-${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onToggle();
        } else {
          onDelete();
        }
        return false;
      },
      background: _swipeBg(color: AppColors.sage, icon: Icons.check_rounded, alignment: Alignment.centerLeft),
      secondaryBackground: _swipeBg(color: AppColors.coral, icon: Icons.delete_outline_rounded, alignment: Alignment.centerRight),
      child: TaskCard(task: task, project: project, onTap: onTap, onToggle: onToggle, onTimer: onTimer),
    );
  }

  Widget _swipeBg({required Color color, required IconData icon, required Alignment alignment}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: Colors.white, size: 22),
      );
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
          children: state.visibleStatusFilters.map((f) {
            final active = state.statusFilter == f;
            return Pressable(
              onTap: () => state.setStatusFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: active ? AppColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTheme.body(12.5, weight: FontWeight.w700, color: active ? AppColors.bg : AppColors.inkSoft),
                  child: Text(f.label),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
