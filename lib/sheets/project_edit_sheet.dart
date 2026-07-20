import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';
import '../widgets/color_picker_dialog.dart';

void showProjectEditSheet(BuildContext context, String? projectId) {
  showAppSheet(
    context,
    title: projectId == null ? '新しい教科' : '教科を編集',
    bodyBuilder: (ctx) => _ProjectEditBody(projectId: projectId),
  );
}

class _ProjectEditBody extends StatefulWidget {
  final String? projectId;
  const _ProjectEditBody({this.projectId});

  @override
  State<_ProjectEditBody> createState() => _ProjectEditBodyState();
}

class _ProjectEditBodyState extends State<_ProjectEditBody> {
  final _nameCtrl = TextEditingController();
  Color _color = AppColors.projectPalette.first;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      final p = context.read<AppState>().projects.firstWhere((p) => p.id == widget.projectId);
      _nameCtrl.text = p.name;
      _color = p.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('教科名を入力してください'), backgroundColor: AppColors.coral));
      return;
    }
    final state = context.read<AppState>();
    if (widget.projectId != null) {
      state.updateProject(widget.projectId!, name: name, color: _color);
    } else {
      state.addProject(name: name, color: _color);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('教科を削除'),
        content: const Text('この教科と関連するタスクをすべて削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AppState>().deleteProject(widget.projectId!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('教科名', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: '例：数学Ⅱ',
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.line, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          Text('カラー', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...AppColors.projectPalette.map((c) => Pressable(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: c, border: Border.all(color: _color == c ? AppColors.ink : Colors.transparent, width: 3)),
                    ),
                  )),
              // 既定の6色のどれにも一致しない場合（カスタムカラーを選んでいる場合）は、
              // 今選んでいる色そのものを、選択中の見た目で一覧の最後に表示する。
              if (!AppColors.projectPalette.contains(_color))
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _color, border: Border.all(color: AppColors.ink, width: 3)),
                ),
              Pressable(
                onTap: () async {
                  final picked = await showColorPickerDialog(context, _color);
                  if (picked != null) setState(() => _color = picked);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface2,
                      border: Border.all(color: AppColors.line, width: 1.5)),
                  child: Icon(Icons.add, size: 16, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(children: [
            if (widget.projectId != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(backgroundColor: AppColors.coralSoft, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18)),
                  child: Text('削除', style: AppTheme.body(14, weight: FontWeight.w700, color: AppColors.coral)),
                ),
              ),
            Expanded(
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('保存する', style: AppTheme.body(14.5, weight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
      ),
    );
  }
}

