import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';

/// 設定 → プロジェクト から開く管理シート。
/// ここでの「プロジェクト」は、タスク作成時の「プロジェクト（任意）」欄
/// （旧グループ）に入力した名前の一覧（AppSettings.knownGroups）のこと。
/// 教科（旧プロジェクト、Projectモデル）とは別物です。
void showProjectsManagementSheet(BuildContext context) {
  showAppSheet(context, title: 'プロジェクトの管理', bodyBuilder: (ctx) => const _ProjectsManagementBody());
}

class _ProjectsManagementBody extends StatefulWidget {
  const _ProjectsManagementBody();
  @override
  State<_ProjectsManagementBody> createState() => _ProjectsManagementBodyState();
}

class _ProjectsManagementBodyState extends State<_ProjectsManagementBody> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _rename(BuildContext context, AppState state, String name) async {
    final ctrl = TextEditingController(text: name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プロジェクト名を変更'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: '例：期末試験')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('変更')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      state.renameKnownGroup(name, result.trim());
    }
  }

  Future<void> _delete(BuildContext context, AppState state, String name, int taskCount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プロジェクトを削除'),
        content: Text(taskCount > 0
            ? 'この候補を削除します。すでに「$name」を設定している$taskCount件のタスクの表示はそのまま残ります（候補一覧からだけ消えます）。'
            : 'この候補を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (confirm == true) state.removeKnownGroup(name);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = state.settings.knownGroups;

    return SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('タスク作成時の「プロジェクト」欄に出てくる候補を管理します。', style: AppTheme.body(12, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('まだ候補がありません', style: AppTheme.body(12.5, color: AppColors.inkFaint))),
            )
          else
            ...groups.map((g) {
              final count = state.tasks.where((t) => t.group == g).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => _rename(context, state, g),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(children: [
                            Expanded(child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(14, weight: FontWeight.w700))),
                            Text('$count件', style: AppTheme.body(11, weight: FontWeight.w600, color: AppColors.inkFaint)),
                          ]),
                        ),
                      ),
                    ),
                    Pressable(
                      onTap: () => _rename(context, state, g),
                      child: Container(width: 32, height: 32, alignment: Alignment.center, child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.inkFaint)),
                    ),
                    Pressable(
                      onTap: () => _delete(context, state, g, count),
                      child: Container(width: 32, height: 32, alignment: Alignment.center, child: const Icon(Icons.close, size: 15, color: AppColors.inkFaint)),
                    ),
                  ]),
                ),
              );
            }),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                decoration: InputDecoration(
                  hintText: '新しいプロジェクト名',
                  filled: true,
                  fillColor: AppColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: () {
                if (_addCtrl.text.trim().isEmpty) return;
                state.registerGroup(_addCtrl.text);
                _addCtrl.clear();
                FocusScope.of(context).unfocus();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ],
      ),
      ),
    );
  }
}
