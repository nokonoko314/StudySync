import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 復習間隔（日数のリスト）を編集するチップ群。
/// タスク作成/編集シートと、忘却曲線の手動設定シートで共有して使います。
class IntervalChipEditor extends StatelessWidget {
  final List<int> intervals;
  final ValueChanged<List<int>> onChanged;

  const IntervalChipEditor({super.key, required this.intervals, required this.onChanged});

  Future<void> _addInterval(BuildContext context) async {
    final controller = TextEditingController(text: '7');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('復習間隔を追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '何日後に復習しますか？（1〜180）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (result != null && result >= 1 && result <= 180 && !intervals.contains(result)) {
      onChanged([...intervals, result]..sort());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...intervals]..sort();
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        ...sorted.map((d) => Chip(
              label: Text('+$d日', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.indigo)),
              backgroundColor: AppColors.indigoSoft,
              deleteIcon: const Icon(Icons.close, size: 13, color: AppColors.indigo),
              onDeleted: () => onChanged(intervals.where((x) => x != d).toList()),
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
        ActionChip(
          avatar: const Icon(Icons.add, size: 13, color: AppColors.inkSoft),
          label: Text('間隔を追加', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          backgroundColor: AppColors.surface2,
          side: const BorderSide(color: AppColors.line),
          visualDensity: VisualDensity.compact,
          onPressed: () => _addInterval(context),
        ),
        if (sorted.isEmpty)
          Text('間隔が設定されていません', style: AppTheme.body(12, color: AppColors.inkFaint)),
      ],
    );
  }
}
