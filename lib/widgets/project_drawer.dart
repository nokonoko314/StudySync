import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../app_theme.dart';
import '../sheets/project_edit_sheet.dart';
import 'pressable.dart';

/// 左から開く教科一覧ドロワー。タップした教科だけに
/// ホーム画面のタスク一覧を絞り込みます（HTMLプロトタイプの#drawerに相当）。
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
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showProjectEditSheet(context, null);
                },
                icon: const Icon(Icons.add, size: 16, color: AppColors.indigo),
                label: Text('新しい教科',
                    style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.indigo)),
                style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.indigoSoft,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
              ),
            ),
          ),
        ]),
      ),
    );
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
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.edit_outlined, size: 14, color: AppColors.inkFaint),
            ),
          ),
        ]),
      ),
    ];
    return rows;
  }
}
