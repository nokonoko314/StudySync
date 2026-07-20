import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';

/// プロジェクト（旧グループ）の作成・編集シート。
/// 名前に加えて、任意で開始日・終了日を設定できる
/// （どちらも未設定のままにもできる）。
void showGroupEditSheet(BuildContext context, String? groupName) {
  showAppSheet(
    context,
    title: groupName == null ? '新しいプロジェクト' : 'プロジェクトを編集',
    bodyBuilder: (ctx) => _GroupEditBody(groupName: groupName),
  );
}

class _GroupEditBody extends StatefulWidget {
  final String? groupName;
  const _GroupEditBody({this.groupName});
  @override
  State<_GroupEditBody> createState() => _GroupEditBodyState();
}

class _GroupEditBodyState extends State<_GroupEditBody> {
  late final TextEditingController _nameCtrl;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final existing = widget.groupName != null ? state.groupProjectByName(widget.groupName!) : null;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _start = existing?.startDate;
    _end = existing?.endDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  void _save() {
    final state = context.read<AppState>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (widget.groupName == null) {
      state.registerGroup(name);
      state.setGroupPeriod(name, startDate: _start, endDate: _end);
    } else if (widget.groupName != name) {
      state.renameKnownGroup(widget.groupName!, name);
      state.setGroupPeriod(name, startDate: _start, endDate: _end);
    } else {
      state.setGroupPeriod(name, startDate: _start, endDate: _end);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final name = widget.groupName!;
    final count = state.tasks.where((t) => t.group == name).length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プロジェクトを削除'),
        content: Text(count > 0
            ? 'このプロジェクトを削除します。すでに「$name」を設定している$count件のタスクの表示はそのまま残ります（一覧からだけ消えます）。'
            : 'このプロジェクトを削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (confirm == true) {
      state.removeKnownGroup(name);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.groupName != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('プロジェクト名'),
        TextField(controller: _nameCtrl, autofocus: !isEditing, decoration: _decoration('例：前期中間テスト')),
        const SizedBox(height: 16),
        _label('期間（任意）'),
        Text('設定しなくてもかまいません。終了日を設定すると、終わったあとに振り返れるようになります。',
            style: AppTheme.body(11, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _dateField('開始日', _start, () => _pick(isStart: true), () => setState(() => _start = null))),
          const SizedBox(width: 10),
          Expanded(child: _dateField('終了日', _end, () => _pick(isStart: false), () => setState(() => _end = null))),
        ]),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isEditing ? '保存する' : '作成する', style: AppTheme.body(14.5, weight: FontWeight.w700)),
          ),
        ),
        if (isEditing) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text('このプロジェクトを削除', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.coral)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.body(11, weight: FontWeight.w700, color: AppColors.inkFaint)),
      const SizedBox(height: 5),
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: _boxDecoration(),
          child: Row(children: [
            Expanded(
              child: Text(
                value != null ? '${value.year}/${value.month}/${value.day}' : '未設定',
                style: AppTheme.body(13, weight: FontWeight.w700, color: value != null ? AppColors.ink : AppColors.inkFaint),
              ),
            ),
            if (value != null)
              Pressable(onTap: onClear, child: Icon(Icons.close, size: 14, color: AppColors.inkFaint)),
          ]),
        ),
      ),
    ]);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.line, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: AppColors.indigo, width: 1.5)),
      );

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line, width: 1.5),
      );
}
