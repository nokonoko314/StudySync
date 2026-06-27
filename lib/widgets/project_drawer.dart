import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../app_theme.dart';
import '../sheets/project_edit_sheet.dart';
import '../sheets/group_management_sheet.dart';
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
              Text('タップすると、その教科のタスクだけ表示します',
                  style: AppTheme.body(11.5, color: AppColors.inkSoft)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _allRow(context, state),
                ...state.projects.expand((p) => _projectRows(context, state, p)),
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
      ...state.settings.knownGroups.map((g) {
        final active = state.activeGroupTag == g;
        final count = state.tasks.where((t) => t.group == g).length;
        return Pressable(
          onTap: () {
            state.setActiveGroupTag(g);
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
                  child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(14, weight: FontWeight.w700))),
              Text('$count', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
            ]),
          ),
        );
      }),
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Pressable(
          onTap: () {
            Navigator.pop(context);
            showProjectsManagementSheet(context);
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.settings_outlined, size: 12, color: AppColors.inkFaint),
            const SizedBox(width: 5),
            Text('設定でプロジェクトを管理', style: AppTheme.body(11.5, weight: FontWeight.w700, color: AppColors.inkFaint)),
          ]),
        ),
      ),
    ];
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

  List<Widget> _projectRows(BuildContext context, AppState state, Project p) {
    final active = state.activeProjectId == p.id;
    final count = state.tasks.where((t) => t.projectId == p.id && !t.completed).length;
    final rows = <Widget>[
      Container(
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
      ),
    ];
    return rows;
  }
}
