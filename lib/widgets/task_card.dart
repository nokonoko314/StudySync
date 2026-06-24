import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import 'pressable.dart';

/// タスク1件分のカード。HTMLプロトタイプの .task-card に相当します。
class TaskCard extends StatelessWidget {
  final Task task;
  final Project? project;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onTimer;

  const TaskCard({
    super.key,
    required this.task,
    required this.project,
    required this.onTap,
    required this.onToggle,
    required this.onTimer,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final borderColor =
        overdue ? AppColors.coral : (task.isReview ? AppColors.sage : AppColors.indigo);
    final pColor = project?.color ?? AppColors.inkFaint;

    return Opacity(
      opacity: task.completed ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pressable(
              onTap: onToggle,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColors.sage : Colors.transparent,
                  border: Border.all(
                      color: task.completed ? AppColors.sage : AppColors.inkFaint, width: 2),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Pressable(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTheme.body(14.5,
                              weight: FontWeight.w700,
                              color: task.completed ? AppColors.inkFaint : AppColors.ink)
                          .copyWith(
                              decoration:
                                  task.completed ? TextDecoration.lineThrough : null),
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _tag(project?.name ?? '未設定', pColor),
                      if (task.group != null) _groupTag(task.group!),
                      if (task.isReview) _reviewTag(),
                      _dueLabel(overdue),
                    ]),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Pressable(
                  onTap: onTimer,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration:
                        const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                    child: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.indigo),
                  ),
                ),
                if (task.timeSpent > 0) ...[
                  const SizedBox(height: 3),
                  Text(formatDuration(task.timeSpent),
                      style: AppTheme.mono(9, color: AppColors.inkFaint)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(text, style: AppTheme.body(10.5, weight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _groupTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  Widget _reviewTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.sageSoft, borderRadius: BorderRadius.circular(99)),
        child: Text('復習', style: AppTheme.body(10.5, weight: FontWeight.w700, color: AppColors.sage)),
      );

  Widget _dueLabel(bool overdue) => Text(
        formatDueLabel(task.due, overdue),
        style: AppTheme.body(11, weight: FontWeight.w600, color: overdue ? AppColors.coral : AppColors.inkSoft),
      );
}
