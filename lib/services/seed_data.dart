import 'dart:math';
import '../models/project.dart';
import '../models/task.dart';
import '../app_theme.dart';
import '../state/app_state.dart';

DateTime _daysFromNow(int n, [int h = 18, int m = 0]) {
  final d = DateTime.now().add(Duration(days: n));
  return DateTime(d.year, d.month, d.day, h, m);
}

final _rnd = Random();

/// 初回起動時（保存データがまだ無いとき）に入れる、操作感を確認するための
/// デモデータ。実運用では削除・置き換えてOKです。
void seedDemoData(AppState state) {
  final pMath = Project(
      id: state.newId('proj'),
      name: '数学Ⅱ',
      color: AppColors.projectPalette[0],
      start: _daysFromNow(5, 9, 0),
      end: _daysFromNow(12, 17, 0));
  final pEng = Project(
      id: state.newId('proj'),
      name: '英語',
      color: AppColors.projectPalette[1],
      start: _daysFromNow(3, 9, 0),
      end: _daysFromNow(10, 17, 0));
  final pPhys = Project(
      id: state.newId('proj'),
      name: '物理',
      color: AppColors.projectPalette[2],
      start: _daysFromNow(20, 9, 0),
      end: _daysFromNow(27, 17, 0));
  final pChem =
      Project(id: state.newId('proj'), name: '化学', color: AppColors.projectPalette[3]);
  state.projects = [pMath, pEng, pPhys, pChem];

  Task mk(
    String title,
    Project p, {
    String? group,
    required DateTime due,
    bool completed = false,
    bool autoReview = true,
    List<int>? intervals,
    int timeSpent = 0,
    List<StudySession>? sessions,
    bool reviewsGenerated = false,
    String notes = '',
  }) {
    final t = Task(
      id: state.newId('task'),
      title: title,
      projectId: p.id,
      group: group,
      due: due,
      completed: completed,
      autoReview: autoReview,
      intervals: intervals ?? const [1, 3, 7, 14, 30],
      timeSpent: timeSpent,
      sessions: sessions ?? [],
      notes: notes,
    );
    t.reviewsGenerated = reviewsGenerated;
    if (completed) t.completedAt = due;
    return t;
  }

  final t1 = mk('三角関数 教科書p.42-50', pMath,
      group: '小テスト対策',
      due: _daysFromNow(0, 19, 0),
      notes: '加法定理と倍角の公式を中心に復習する。',
      timeSpent: 1860,
      sessions: [
        StudySession(date: _daysFromNow(-1, 20, 0), durationSeconds: 1260),
        StudySession(date: _daysFromNow(0, 8, 0), durationSeconds: 600),
      ]);
  final t2 = mk('数列の漸化式 演習プリント', pMath, group: '小テスト対策', due: _daysFromNow(1, 21, 0));
  final t3 = mk('ベクトルの内積 章末問題', pMath, due: _daysFromNow(-1, 18, 0));
  final t4 = mk('積分の応用 教科書p.88', pMath,
      due: _daysFromNow(-4, 18, 0),
      completed: true,
      timeSpent: 2700,
      sessions: [
        StudySession(date: _daysFromNow(-4, 17, 30), durationSeconds: 2700)
      ],
      reviewsGenerated: true);

  final t5 = mk('Unit 5 単語テスト範囲', pEng, group: '単語', due: _daysFromNow(2, 17, 0));
  final t6 = mk('長文読解プリント 第3回', pEng, due: _daysFromNow(-2, 18, 0));
  final t7 = mk('文法 関係代名詞まとめ', pEng,
      group: '文法',
      due: _daysFromNow(-6, 18, 0),
      completed: true,
      timeSpent: 1500,
      sessions: [
        StudySession(date: _daysFromNow(-6, 19, 0), durationSeconds: 1500)
      ],
      reviewsGenerated: true);

  final t8 = mk('運動方程式 章末問題', pPhys,
      due: _daysFromNow(4, 18, 0),
      timeSpent: 600,
      sessions: [
        StudySession(date: _daysFromNow(-1, 16, 0), durationSeconds: 600)
      ]);
  final t9 = mk('力学 基礎問題集 p.20', pPhys, due: _daysFromNow(9, 18, 0));

  final t10 = mk('周期表 暗記', pChem,
      group: '暗記', due: _daysFromNow(1, 18, 0), autoReview: false, intervals: const []);
  final t11 = mk('モル計算 演習', pChem, group: '暗記', due: _daysFromNow(6, 18, 0));

  final r1 = Task(
      id: state.newId('task'),
      title: '復習：積分の応用 教科書p.88',
      projectId: pMath.id,
      due: _daysFromNow(0, 9, 0),
      isReview: true,
      parentId: t4.id,
      autoReview: false,
      intervals: const []);
  final r2 = Task(
      id: state.newId('task'),
      title: '復習：積分の応用 教科書p.88',
      projectId: pMath.id,
      due: _daysFromNow(-2, 9, 0),
      isReview: true,
      parentId: t4.id,
      autoReview: false,
      intervals: const []);
  final r3 = Task(
      id: state.newId('task'),
      title: '復習：文法 関係代名詞まとめ',
      projectId: pEng.id,
      group: '文法',
      due: _daysFromNow(0, 12, 0),
      isReview: true,
      parentId: t7.id,
      autoReview: false,
      intervals: const []);

  // 統計画面のグラフに表情をつけるため、過去の学習セッションを追加で散らす
  final pool = [t1, t2, t3, t5, t6, t8, t9, t10, t11];
  for (var i = 1; i <= 13; i++) {
    final t = pool[i % pool.length];
    final dur = 600 + _rnd.nextInt(2400);
    t.sessions.add(
        StudySession(date: _daysFromNow(-i, 16 + (i % 4), 0), durationSeconds: dur));
    t.timeSpent += dur;
  }

  state.tasks = [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, r1, r2, r3];
}
