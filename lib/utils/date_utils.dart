// 日付・時間のフォーマット用ユーティリティ。
// HTML プロトタイプの formatDueLabel / formatDuration などと同じ仕様です。

/// 学習時間の表示形式（設定 →「表示」から変更可能）。
/// AppColors の accent color と同じく、グローバルなミュータブル値として持ち、
/// 設定を変えるとアプリ全体の表示にすぐ反映されるようにしている。
class TimeDisplaySettings {
  /// true: 60分以上は「1時間10分」のように時間＋分で表示
  /// false: 常に「70分」のように分だけで表示
  static bool useHourMinute = true;
}

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

/// 分数を、設定に応じて「70分」または「1時間10分」の形式にする。
/// カレンダー・統計・プロジェクトの各画面で、学習時間の表示に共通で使う。
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0分';
  if (!TimeDisplaySettings.useHourMinute || minutes < 60) return '$minutes分';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '$h時間$m分' : '$h時間';
}

String formatDuration(int seconds) {
  if (seconds <= 0) return '0分';
  if (seconds < 60) return '$seconds秒';
  return formatMinutes((seconds / 60).round());
}

String formatHMS(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${pad2(h)}:${pad2(m)}:${pad2(s)}';
}
