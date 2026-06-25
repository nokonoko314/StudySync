import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/interval_chip_editor.dart';
import '../widgets/pressable.dart';

Future<void> showAddEditTaskSheet(BuildContext context, {String? taskId, String? projectIdHint}) {
  return showAppSheet(
    context,
    title: taskId == null ? '新しいタスク' : 'タスクを編集',
    bodyBuilder: (ctx) => _AddEditTaskBody(taskId: taskId, projectIdHint: projectIdHint),
  );
}

class _AddEditTaskBody extends StatefulWidget {
  final String? taskId;
  final String? projectIdHint;
  const _AddEditTaskBody({this.taskId, this.projectIdHint});

  @override
  State<_AddEditTaskBody> createState() => _AddEditTaskBodyState();
}

class _AddEditTaskBodyState extends State<_AddEditTaskBody> {
  final _titleCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _projectId;
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  bool _autoReview = true;
  List<int> _intervals = [1, 3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (widget.taskId != null) {
      final t = state.taskById(widget.taskId!)!;
      _titleCtrl.text = t.title;
      _groupCtrl.text = t.group ?? '';
      _notesCtrl.text = t.notes;
      _projectId = t.projectId;
      _due = t.due;
      _autoReview = t.autoReview;
      _intervals = [...t.intervals];
    } else {
      _projectId = widget.projectIdHint ?? (state.projects.isNotEmpty ? state.projects.first.id : null);
      _autoReview = state.settings.globalAutoReview;
      _intervals = [...state.settings.globalIntervals];
      _due = state.defaultDueDate();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _groupCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _due = DateTime(picked.year, picked.month, picked.day, _due.hour, _due.minute));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    if (picked != null) setState(() => _due = DateTime(_due.year, _due.month, _due.day, picked.hour, picked.minute));
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.coral : AppColors.ink,
    ));
  }

  void _save() {
    final state = context.read<AppState>();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _toast('タスク名を入力してください', error: true);
      return;
    }
    if (_projectId == null) {
      _toast('教科を選択してください', error: true);
      return;
    }
    final group = _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim();
    if (widget.taskId != null) {
      state.updateTask(
        widget.taskId!,
        title: title,
        projectId: _projectId,
        group: group,
        clearGroup: group == null,
        due: _due,
        notes: _notesCtrl.text.trim(),
        autoReview: _autoReview,
        intervals: _intervals,
      );
    } else {
      state.addTask(
        title: title,
        projectId: _projectId!,
        group: group,
        due: _due,
        notes: _notesCtrl.text.trim(),
        autoReview: _autoReview,
        intervals: _intervals,
      );
    }
    Navigator.pop(context);
    _toast('保存しました');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groupOptions = state.settings.knownGroups;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('タスク名'),
          TextField(controller: _titleCtrl, decoration: _decoration('例：数学Ⅱ 三角関数 教科書p.42-50')),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('教科'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: _boxDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _projectId,
                      isExpanded: true,
                      items: state.projects
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: AppTheme.body(14))))
                          .toList(),
                      onChanged: (v) => setState(() => _projectId = v),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          _label('プロジェクト（任意）'),
          TextField(controller: _groupCtrl, decoration: _decoration('例：期末試験')),
          if (groupOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: groupOptions.map((g) {
                  return Container(
                    padding: const EdgeInsets.only(left: 10, right: 4, top: 3, bottom: 3),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Pressable(
                        onTap: () => setState(() => _groupCtrl.text = g),
                        child: Text(g, style: AppTheme.body(11, color: AppColors.inkSoft)),
                      ),
                      Pressable(
                        onTap: () => context.read<AppState>().removeKnownGroup(g),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.close, size: 11, color: AppColors.inkFaint),
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          _label('期限日時'),
          Row(children: [
            Expanded(
              child: Pressable(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  decoration: _boxDecoration(),
                  child: Text('${_due.year}-${pad2(_due.month)}-${pad2(_due.day)}', style: AppTheme.body(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Pressable(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  decoration: _boxDecoration(),
                  child: Text('${pad2(_due.hour)}:${pad2(_due.minute)}', style: AppTheme.body(14)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _label('メモ（任意）'),
          TextField(controller: _notesCtrl, maxLines: 3, decoration: _decoration('補足・参照ページなど')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('忘却曲線に沿って自動で復習を追加', style: AppTheme.body(14, weight: FontWeight.w700)),
                Text('完了にした時点から、下の間隔で復習タスクを自動生成します', style: AppTheme.body(11.5, color: AppColors.inkSoft)),
              ]),
            ),
            CupertinoSwitch(
                value: _autoReview, activeColor: AppColors.sage, onChanged: (v) => setState(() => _autoReview = v)),
          ]),
          if (_autoReview) ...[
            const SizedBox(height: 14),
            _label('復習間隔（完了からの日数）'),
            IntervalChipEditor(intervals: _intervals, onChanged: (v) => setState(() => _intervals = v)),
          ],
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
              child: Text('保存する', style: AppTheme.body(14.5, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.indigo, width: 1.5)),
      );

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line, width: 1.5),
      );
}
