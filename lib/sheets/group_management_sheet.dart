import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/group_project.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';
import 'group_edit_sheet.dart';
import 'project_history_sheet.dart';

/// 「プロジェクト」（旧グループ）の一覧画面。
/// タスク作成時の「プロジェクト（任意）」欄の候補と同じデータを使う。
/// 教科（Projectモデル）とは別物。
///
/// - 進行中のプロジェクトはコーラル色でハイライトして並ぶ
/// - 終了したプロジェクト（終了日が過ぎたもの）は下にまとまり、
///   タップすると当時のタスク・学習時間を振り返れる
/// - 各プロジェクトには「タスク件数」「学習時間」の集計が付く
void showProjectsManagementSheet(BuildContext context) {
  showAppSheet(context, title: 'プロジェクト', bodyBuilder: (ctx) => const _GroupListBody());
}

class _GroupListBody extends StatelessWidget {
  const _GroupListBody();

  int _minutesFor(AppState state, String name) {
    final total = state.tasks.where((t) => t.group == name).fold<int>(0, (s, t) => s + t.timeSpent);
    return (total / 60).round();
  }

  int _countFor(AppState state, String name) => state.tasks.where((t) => t.group == name).length;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.settings.knownGroups;
    final ongoing = all.where((g) => !g.isPast).toList();
    final ended = all.where((g) => g.isPast).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('教科をまたいだ「テスト期間」や「対策」ごとに、タスクをまとめて管理・振り返りできます。',
                style: AppTheme.body(12, color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showGroupEditSheet(context, null),
                icon: const Icon(Icons.add, size: 16, color: AppColors.coral),
                label: Text('新しいプロジェクト', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.coral)),
                style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.coralSoft, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
            const SizedBox(height: 20),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('まだプロジェクトがありません。上のボタンから作ってみましょう。',
                      textAlign: TextAlign.center, style: AppTheme.body(12.5, color: AppColors.inkFaint)),
                ),
              ),
            if (ongoing.isNotEmpty) ...[
              _sectionLabel('進行中', AppColors.coral),
              const SizedBox(height: 8),
              ...ongoing.map((g) => _ongoingCard(context, state, g)),
              const SizedBox(height: 12),
            ],
            if (ended.isNotEmpty) ...[
              _sectionLabel('終了したプロジェクト', AppColors.inkFaint),
              const SizedBox(height: 4),
              Text('タップすると、当時の記録を振り返れます', style: AppTheme.body(11, color: AppColors.inkFaint)),
              const SizedBox(height: 8),
              ...ended.map((g) => _endedCard(context, state, g)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(text, style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft).copyWith(letterSpacing: .3)),
      ]);

  Widget _ongoingCard(BuildContext context, AppState state, GroupProject g) {
    final minutes = _minutesFor(state, g.name);
    final count = _countFor(state, g.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: () => showGroupEditSheet(context, g.name),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.coralSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.coral.withOpacity(.35), width: 1.2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(15, weight: FontWeight.w700, color: AppColors.ink)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.coral),
            ]),
            if (g.hasPeriod) ...[
              const SizedBox(height: 3),
              Text(_periodLabel(g), style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.coral)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              _statChip(Icons.checklist_rounded, '$count件'),
              const SizedBox(width: 8),
              _statChip(Icons.schedule_rounded, '$minutes分'),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _endedCard(BuildContext context, AppState state, GroupProject g) {
    final minutes = _minutesFor(state, g.name);
    final count = _countFor(state, g.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: () => showProjectHistorySheet(context, g.name),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.event_repeat_rounded, size: 14, color: AppColors.inkFaint),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(14, weight: FontWeight.w700, color: AppColors.inkSoft)),
                if (g.hasPeriod) Text(_periodLabel(g), style: AppTheme.body(10.5, color: AppColors.inkFaint)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$count件', style: AppTheme.mono(11, color: AppColors.inkSoft)),
              Text('$minutes分', style: AppTheme.mono(11, color: AppColors.inkFaint)),
            ]),
            const SizedBox(width: 4),
            Pressable(
              onTap: () => showGroupEditSheet(context, g.name),
              child: Container(width: 30, height: 30, alignment: Alignment.center, child: const Icon(Icons.edit_outlined, size: 13, color: AppColors.inkFaint)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppColors.coral),
          const SizedBox(width: 4),
          Text(text, style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.ink)),
        ]),
      );

  String _periodLabel(GroupProject g) {
    String fmt(DateTime d) => '${d.year}/${d.month}/${d.day}';
    if (g.startDate != null && g.endDate != null) return '${fmt(g.startDate!)} 〜 ${fmt(g.endDate!)}';
    if (g.startDate != null) return '${fmt(g.startDate!)} 〜';
    return '〜 ${fmt(g.endDate!)}';
  }
}
