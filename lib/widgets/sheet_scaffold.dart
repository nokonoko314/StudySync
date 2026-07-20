import 'package:flutter/material.dart';
import '../app_theme.dart';

/// すべてのシート（タスク追加・詳細・タイマー・設定系など）で共通の
/// 「グリップ＋タイトル＋閉じるボタン」のヘッダーを持つ、角丸の
/// 下からスライドするシートを表示するヘルパー。
///
/// [isDismissible] / [enableDrag] を false にすると、スワイプでの
/// dismiss を禁止できます（タイマー画面のように、閉じる前に
/// 明示的な後始末をしたい場合に使用）。
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder bodyBuilder,
  List<Widget>? actions,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
                child: Row(children: [
                  Expanded(child: Text(title, style: AppTheme.display(17.5))),
                  ...(actions ??
                      [
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.ink),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ]),
                ]),
              ),
              Flexible(child: bodyBuilder(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}
