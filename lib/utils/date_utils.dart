/// 日付・時間のフォーマット用ユーティリティ。
/// HTML プロトタイプの formatDueLabel / formatDuration などと同じ仕様です。

const List<String> weekdaysJp = ['日', '月', '火', '水', '木', '金', '土'];

String pad2(int n) => n < 10 ? '0$n' : '$n';

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Dart の DateTime.weekday は 月曜=1...日曜=7。
/// weekdaysJp は 日曜始まり(index 0)の配列なので %7 で変換する。
String weekdayJp(DateTime d) => weekdaysJp[d.weekday % 7];

String formatJPDate(DateTime d) =>
    '${d.year}年${d.month}月${d.day}日(${weekdayJp(d)})';

String fmtShort(DateTime d) => '${d.month}/${d.day}';

String formatDueLabel(DateTime due, bool overdue) {
  final hh = '${pad2(due.hour)}:${pad2(due.minute)}';
  if (overdue) return '${due.month}/${due.day}(${weekdayJp(due)})に期限切れ';
  final now = DateTime.now();
  if (sameDay(due, now)) return '今日 $hh';
  if (sameDay(due, now.add(const Duration(days: 1)))) return '明日 $hh';
  return '${due.month}/${due.day}(${weekdayJp(due)}) $hh';
}

String formatDuration(int seconds) {
  if (seconds <= 0) return '0分';
  if (seconds < 60) return '$seconds秒';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes分';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '$h時間$m分' : '$h時間';
}

String formatHMS(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${pad2(h)}:${pad2(m)}:${pad2(s)}';
}
