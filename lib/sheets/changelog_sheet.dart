import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../changelog.dart';
import '../widgets/sheet_scaffold.dart';

void showChangelogSheet(BuildContext context) {
  showAppSheet(context, title: '変更履歴', bodyBuilder: (ctx) => const _ChangelogBody());
}

class _ChangelogBody extends StatelessWidget {
  const _ChangelogBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: kChangelog.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(99)),
                    child: Text(entry.version, style: AppTheme.mono(12, weight: FontWeight.w700, color: AppColors.indigo)),
                  ),
                ]),
                const SizedBox(height: 8),
                ...entry.changes.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 2),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.inkFaint, shape: BoxShape.circle)),
                        ),
                        Expanded(child: Text(c, style: AppTheme.body(13, color: AppColors.inkSoft, weight: FontWeight.w400).copyWith(height: 1.5))),
                      ]),
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
