import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../models/group_project.dart';
import '../app_theme.dart';
import '../sheets/project_edit_sheet.dart';
import '../sheets/group_management_sheet.dart';
import '../sheets/project_history_sheet.dart';
import 'pressable.dart';

/// 左から開くドロワー。「教科」と「プロジェクト」、それぞれタップした
/// 1件だけにホーム画面のタスク一覧を絞り込みます
/// （HTMLプロトタイプの#drawerに相当）。
class ProjectDrawer extends StatelessWidget {
  const ProjectDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('教科', style: AppTheme.display(19)),
              const SizedBox(height: 2),
              Text('タップすると、その教科のタスクだけ表示します（長押しで並び替え）',
                  style: AppTheme.body(11.5, color: AppColors.inkSoft)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _allRow(context, state),
                ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.projects.length,
                  onReorder: (oldIndex, newIndex) => state.reorderProjects(oldIndex, newIndex),
                  itemBuilder: (ctx, i) {
                    final p = state.projects[i];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(p.id),
                      index: i,
                      child: _projectRow(context, state, p),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Pressable(
                    onTap: () {
                      Navigator.pop(context);
                      showProjectEditSheet(context, null);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add, size: 15, color: AppColors.indigo),
                        const SizedBox(width: 6),
                        Text('新しい教科', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.indigo)),
                      ]),
                    ),
                  ),
                ),
                if (state.settings.knownGroups.isNotEmpty) ..._groupSection(context, state),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _groupSection(BuildContext context, AppState state) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 10, 2),
        child: Text('プロジェクト', style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkFaint).copyWith(letterSpacing: .4)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
        child: Text('タップすると、そのプロジェクトのタスクだけ表示します',
            style: AppTheme.body(10.5, color: AppColors.inkFaint)),
      ),
      ...(() {
        // 進行中・期間未設定のものを先に、終わったプロジェクトは下にまとめる
        // ことで、「過去を振り返る」ときも一覧の下側を見ればすぐ見つかる。
        final sorted = [...state.settings.knownGroups]
          ..sort((a, b) {
            if (a.isPast != b.isPast) return a.isPast ? 1 : -1;
            return 0;
          });
        return sorted.map((g) {
          final active = state.activeGroupTag == g.name;
          final count = state.tasks.where((t) => t.group == g.name).length;
          return Pressable(
            onTap: () {
              if (g.isPast) {
                Navigator.pop(context);
                showProjectHistorySheet(context, g.name);
                return;
              }
              state.setActiveGroupTag(g.name);
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                  color: active ? AppColors.coralSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: AppColors.coralSoft, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.label_outline, size: 13, color: AppColors.coral),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(14, weight: FontWeight.w700)),
                    if (g.hasPeriod)
                      Text(_periodLabel(g), style: AppTheme.body(10, color: g.isPast ? AppColors.inkFaint : AppColors.coral)),
                  ]),
                ),
                if (g.isPast)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('振り返る', style: AppTheme.body(9.5, weight: FontWeight.w700, color: AppColors.inkFaint)),
                  ),
                Text('$count', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
              ]),
            ),
          );
        });
      })(),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Pressable(
          onTap: () {
            Navigator.pop(context);
            showProjectsManagementSheet(context);
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.inkFaint),
            const SizedBox(width: 5),
            Text('プロジェクトを管理・振り返る', style: AppTheme.body(11.5, weight: FontWeight.w700, color: AppColors.inkFaint)),
          ]),
        ),
      ),
    ];
  }

  String _periodLabel(GroupProject g) {
    String fmt(DateTime d) => '${d.month}/${d.day}';
    if (g.startDate != null && g.endDate != null) return '${fmt(g.startDate!)}〜${fmt(g.endDate!)}';
    if (g.startDate != null) return '${fmt(g.startDate!)}〜';
    if (g.endDate != null) return '〜${fmt(g.endDate!)}';
    return '';
  }

  Widget _allRow(BuildContext context, AppState state) {
    final active = state.activeProjectId == null;
    return Pressable(
      onTap: () {
        state.setActiveProject(null);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
            color: active ? AppColors.indigoSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(13)),
        child: Row(children: [
          const Icon(Icons.folder_outlined, size: 16, color: AppColors.inkSoft),
          const SizedBox(width: 10),
          Expanded(
              child: Text('すべてのタスク', style: AppTheme.body(14, weight: FontWeight.w700))),
          Text('${state.tasks.length}',
              style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
        ]),
      ),
    );
  }

  Widget _projectRow(BuildContext context, AppState state, Project p) {
    final active = state.activeProjectId == p.id;
    final count = state.tasks.where((t) => t.projectId == p.id && !t.completed).length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
          color: active ? AppColors.indigoSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        Expanded(
          child: Pressable(
            onTap: () {
              state.setActiveProject(p.id);
              Navigator.pop(context);
            },
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(14, weight: FontWeight.w700))),
              Text('$count', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
            ]),
          ),
        ),
        Pressable(
          onTap: () => showProjectEditSheet(context, p.id),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.inkFaint),
          ),
        ),
      ]),
    );
  }
}
