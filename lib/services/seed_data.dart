import '../models/project.dart';
import '../models/task.dart';
import '../app_theme.dart';
import '../state/app_state.dart';

DateTime _daysFromNow(int n, [int h = 18, int m = 0]) {
  final d = DateTime.now().add(Duration(days: n));
  return DateTime(d.year, d.month, d.day, h, m);
}

/// 初回起動時（保存データがまだ無いとき）に入れる、操作感を確認するための
/// 最小限のデモデータ。多すぎると分かりにくいので、3件程度に絞っています。
void seedDemoData(AppState state) {
  final pMath = Project(id: state.newId('proj'), name: '数学Ⅱ', color: AppColors.projectPalette[0]);
  state.projects = [pMath];

  Task mk(
    String title,
    Project p, {
    String? group,
    required DateTime due,
    bool completed = false,
    int timeSpent = 0,
    List<StudySession>? sessions,
    String notes = '',
  }) {
    final t = Task(
      id: state.newId('task'),
      title: title,
      projectId: p.id,
      group: group,
      due: due,
      completed: completed,
      timeSpent: timeSpent,
      sessions: sessions ?? [],
      notes: notes,
    );
    if (completed) t.completedAt = due;
    return t;
  }

  final t1 = mk('三角関数 教科書p.42-50', pMath,
      due: _daysFromNow(0, 19, 0),
      notes: '加法定理と倍角の公式を中心に復習する。',
      timeSpent: 1260,
      sessions: [StudySession(id: state.newId('sess'), date: _daysFromNow(-1, 20, 0), durationSeconds: 1260)]);
  final t2 = mk('数列の漸化式 演習プリント', pMath, due: _daysFromNow(1, 21, 0));
  final t3 = mk('ベクトルの内積 章末問題', pMath, due: _daysFromNow(-1, 18, 0));

  state.tasks = [t1, t2, t3];

  for (final t in state.tasks) {
    if (t.group != null && !state.settings.knownGroups.contains(t.group)) {
      state.settings.knownGroups.add(t.group!);
    }
  }
}
