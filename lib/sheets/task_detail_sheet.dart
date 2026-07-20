import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/forgetting_curve_chart.dart';
import 'add_edit_task_sheet.dart';
import 'timer_sheet.dart';

void showTaskDetailSheet(BuildContext context, String taskId) {
  showAppSheet(
    context,
    title: 'タスクの詳細',
    actions: [
      IconButton(
        icon: Icon(Icons.edit_outlined, color: AppColors.ink),
        onPressed: () {
          Navigator.pop(context);
          showAddEditTaskSheet(context, taskId: taskId);
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, color: AppColors.coral),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('タスクを削除'),
              content: const Text('このタスクを削除しますか？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('削除', style: TextStyle(color: AppColors.coral)),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            context.read<AppState>().deleteTask(taskId);
            Navigator.pop(context);
          }
        },
      ),
      IconButton(icon: Icon(Icons.close, color: AppColors.ink), onPressed: () => Navigator.pop(context)),
    ],
    bodyBuilder: (ctx) => _TaskDetailBody(taskId: taskId),
  );
}

class _TaskDetailBody extends StatelessWidget {
  final String taskId;
  const _TaskDetailBody({required this.taskId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.taskById(taskId);
    if (t == null) return const SizedBox();
    final project = state.projectById(t.projectId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.title, style: AppTheme.display(18)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _statusBadge(t.status),
            if (project != null) _tag(project.name, project.color),
            if (t.group != null) _groupTag(t.group!),
            if (t.isReview) _reviewTag('復習タスク'),
          ]),
          const SizedBox(height: 14),
          if (t.isReview)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.refresh, size: 14, color: AppColors.sage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('忘却曲線にもとづいて自動生成された復習タスクです。',
                      style: AppTheme.body(12, color: AppColors.sage)),
                ),
              ]),
            ),
          if (t.isReview && t.parentId != null && state.taskById(t.parentId!) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showTaskDetailSheet(context, t.parentId!);
                  },
                  style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.indigoSoft, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: Text('元のタスクを見る', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.indigo)),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Column(children: [
              _detailRow('期限', '${formatJPDate(t.due)} ${pad2(t.due.hour)}:${pad2(t.due.minute)}'),
              if (t.completed && t.completedAt != null) _detailRow('完了日時', formatJPDate(t.completedAt!)),
              _detailRow('自動復習', t.autoReview ? 'ON' : 'OFF', isLast: true),
            ]),
          ),
          if (t.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('メモ', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
              child: Text(t.notes, style: AppTheme.body(12.5, color: AppColors.inkSoft)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => state.toggleComplete(t.id),
              style: OutlinedButton.styleFrom(
                backgroundColor: t.completed ? Colors.transparent : AppColors.indigo,
                side: t.completed ? BorderSide(color: AppColors.line) : BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(t.completed ? '未完了に戻す' : '完了にする',
                  style: AppTheme.body(14, weight: FontWeight.w700, color: t.completed ? AppColors.inkSoft : Colors.white)),
            ),
          ),
          const SizedBox(height: 18),
          Text('学習時間', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(formatDuration(t.timeSpent), style: AppTheme.mono(24, color: AppColors.ink)),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showTimerSheet(context, t.id);
                  },
                  icon: Icon(Icons.play_arrow, size: 14, color: AppColors.indigo),
                  label: Text('計測する', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.indigo)),
                  style: OutlinedButton.styleFrom(backgroundColor: AppColors.indigoSoft, side: BorderSide.none),
                ),
              ]),
              if (t.sessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: ([...t.sessions]..sort((a, b) => b.date.compareTo(a.date))).take(8).map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)}',
                              style: AppTheme.body(12, color: AppColors.inkSoft)),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(formatDuration(s.durationSeconds), style: AppTheme.mono(12, weight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('記録を削除'),
                                    content: Text('${s.date.month}/${s.date.day} ${pad2(s.date.hour)}:${pad2(s.date.minute)} の記録（${formatDuration(s.durationSeconds)}）を削除しますか？'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: AppColors.coral))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  state.deleteSession(t.id, s.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.close, size: 14, color: AppColors.inkFaint),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    }).toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('まだ記録がありません', style: AppTheme.body(12, color: AppColors.inkFaint)),
                ),
            ]),
          ),
          if (!t.isReview) ...[
            const SizedBox(height: 18),
            Text('忘却曲線プレビュー', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: ForgettingCurveChart(intervals: t.intervals),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isLast = false}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTheme.body(13, color: AppColors.inkSoft)),
          Text(value, style: AppTheme.body(13, weight: FontWeight.w700)),
        ]),
      );

  Widget _statusBadge(String status) {
    final colors = {
      '完了': (AppColors.sageSoft, AppColors.sage),
      '期限切れ': (AppColors.coralSoft, AppColors.coral),
      '未完了': (AppColors.indigoSoft, AppColors.indigo),
    };
    final c = colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(99)),
      child: Text(status, style: AppTheme.body(11.5, weight: FontWeight.w700, color: c.$2)),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(text, style: AppTheme.body(10.5, weight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _groupTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  Widget _reviewTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.sage)),
      );
}
