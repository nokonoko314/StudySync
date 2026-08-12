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

    return AnimatedOpacity(
      opacity: task.completed ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pressable(
              onTap: onToggle,
              child: _AnimatedCheckbox(checked: task.completed),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Pressable(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: AppTheme.body(14.5,
                              weight: FontWeight.w700,
                              color: task.completed ? AppColors.inkFaint : AppColors.ink)
                          .copyWith(
                              decoration:
                                  task.completed ? TextDecoration.lineThrough : null),
                      child: Text(task.title),
                    ),
                    const SizedBox(height: 6),
                    // 主役は教科タグと期限。プロジェクト名・復習マークは
                    // 情報量を抑えるため、控えめなテキスト/アイコンとして期限の隣に添える。
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      _tag(project?.name ?? '未設定', pColor),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (task.isReview) ...[
                          Icon(Icons.repeat_rounded, size: 12, color: AppColors.sage),
                          const SizedBox(width: 4),
                        ],
                        if (task.group != null) ...[
                          Text(task.group!, style: AppTheme.body(10.5, weight: FontWeight.w600, color: AppColors.inkFaint)),
                          Text('  ・  ', style: AppTheme.body(10.5, color: AppColors.inkFaint)),
                        ],
                        _dueLabel(overdue),
                      ]),
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
                        BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                    child: Icon(Icons.access_time_rounded, size: 16, color: AppColors.indigo),
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

  Widget _dueLabel(bool overdue) => Text(
        formatDueLabel(task.due, overdue),
        style: AppTheme.body(11, weight: FontWeight.w600, color: overdue ? AppColors.coral : AppColors.inkSoft),
      );
}

/// タスク完了のチェックボックス。完了にした瞬間だけ、軽くポンと弾む演出をつける。
class _AnimatedCheckbox extends StatefulWidget {
  final bool checked;
  const _AnimatedCheckbox({required this.checked});

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 65),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked && !oldWidget.checked) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.scale(scale: _bounce.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.checked ? AppColors.sage : Colors.transparent,
          border: Border.all(color: widget.checked ? AppColors.sage : AppColors.inkFaint, width: 2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: widget.checked
              ? const Icon(Icons.check, size: 13, color: Colors.white, key: ValueKey('checked'))
              : const SizedBox.shrink(key: ValueKey('unchecked')),
        ),
      ),
    );
  }
}
