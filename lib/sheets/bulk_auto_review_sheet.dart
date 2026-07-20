import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';

/// すでに作成済みのタスクをまとめて選び、忘却曲線にもとづく自動復習の
/// 追加をOFFにするための画面。
/// 「作ったときは自動復習ONにしていたけど、このタスクではやっぱり
/// いらなかった」というタスクをまとめて整理したいときに使う。
void showBulkAutoReviewSheet(BuildContext context) {
  showAppSheet(context, title: '自動復習をまとめてOFF', bodyBuilder: (ctx) => const _BulkAutoReviewBody());
}

class _BulkAutoReviewBody extends StatefulWidget {
  const _BulkAutoReviewBody();
  @override
  State<_BulkAutoReviewBody> createState() => _BulkAutoReviewBodyState();
}

class _BulkAutoReviewBodyState extends State<_BulkAutoReviewBody> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // 復習タスク自体（isReview）は対象外。自動復習がONのものだけを一覧にする。
    final targets = state.tasks.where((t) => !t.isReview && t.autoReview).toList()
      ..sort((a, b) => a.due.compareTo(b.due));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('自動復習がONになっているタスクの一覧です。選んで一括でOFFにできます。',
                style: AppTheme.body(12.5, color: AppColors.inkSoft)),
            const SizedBox(height: 10),
            if (targets.isNotEmpty)
              Pressable(
                onTap: () {
                  setState(() {
                    if (_selected.length == targets.length) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(targets.map((t) => t.id));
                    }
                  });
                },
                child: Row(children: [
                  Icon(
                    _selected.length == targets.length ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 6),
                  Text('すべて選択', style: AppTheme.body(12.5, weight: FontWeight.w700, color: AppColors.indigo)),
                ]),
              ),
          ]),
        ),
        if (targets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text('自動復習がONのタスクはありません', style: AppTheme.body(12.5, color: AppColors.inkFaint)),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: targets.map((t) {
                  final checked = _selected.contains(t.id);
                  final reviewCount = state.tasks.where((c) => c.parentId == t.id && c.isReview).length;
                  return Pressable(
                    onTap: () => setState(() {
                      if (checked) {
                        _selected.remove(t.id);
                      } else {
                        _selected.add(t.id);
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: checked ? AppColors.indigoSoft : AppColors.surface2,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: checked ? AppColors.indigo : Colors.transparent, width: 1.5),
                      ),
                      child: Row(children: [
                        Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 19, color: checked ? AppColors.indigo : AppColors.inkFaint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(13, weight: FontWeight.w700)),
                            Text(
                              reviewCount > 0 ? '${t.due.month}/${t.due.day}まで・復習${reviewCount}件生成済み' : '${t.due.month}/${t.due.day}まで',
                              style: AppTheme.body(10.5, color: AppColors.inkFaint),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      state.bulkDisableAutoReview(_selected);
                      final count = _selected.length;
                      setState(() => _selected.clear());
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$count件のタスクで自動復習をOFFにしました'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.ink,
                      ));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surface2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selected.isEmpty ? 'タスクを選んでください' : '${_selected.length}件をOFFにする',
                style: AppTheme.body(14, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
