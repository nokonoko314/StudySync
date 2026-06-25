import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/project.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';
import 'project_edit_sheet.dart';

/// 設定画面から開く「教科の管理」シート。
/// ドロワーと同じデータを使い、追加・編集・削除ができます。
void showSubjectsSheet(BuildContext context) {
  showAppSheet(context, title: '教科の管理', bodyBuilder: (ctx) => const _SubjectsBody());
}

class _SubjectsBody extends StatelessWidget {
  const _SubjectsBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('まだ教科がありません。下のボタンから追加してください。',
                    textAlign: TextAlign.center, style: AppTheme.body(12.5, color: AppColors.inkFaint)),
              ),
            )
          else
            ...state.projects.map((p) => _row(context, state, p)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showProjectEditSheet(context, null),
              icon: const Icon(Icons.add, size: 16, color: AppColors.indigo),
              label: Text('新しい教科を追加', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.indigo)),
              style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.indigoSoft, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppState state, Project p) {
    final count = state.tasks.where((t) => t.projectId == p.id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(13)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(
            child: Pressable(
              onTap: () => showProjectEditSheet(context, p.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(p.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(14, weight: FontWeight.w700))),
                  Text('$count件', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
                ]),
              ),
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
    );
  }
}
