import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../services/persistence_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/seed_data.dart';

enum AppScreen { home, calendar, stats, settings }

enum StatusFilter { incomplete, completed, overdue, reviewOnly, all }

extension StatusFilterLabel on StatusFilter {
  String get label {
    switch (this) {
      case StatusFilter.incomplete:
        return '未完了';
      case StatusFilter.completed:
        return '完了';
      case StatusFilter.overdue:
        return '期限切れ';
      case StatusFilter.reviewOnly:
        return '復習のみ';
      case StatusFilter.all:
        return 'すべて';
    }
  }
}

/// アプリ全体の状態と操作。HTMLプロトタイプの `state` オブジェクト＋
/// 各種 render関数 / イベントハンドラに相当するロジックを、
/// ChangeNotifier 1クラスにまとめたものです。
///
/// 画面側は `context.watch<AppState>()` で読み取り、
/// `context.read<AppState>()` で操作（メソッド呼び出し）します。
class AppState extends ChangeNotifier {
  List<Project> projects = [];
  List<Task> tasks = [];
  AppSettings settings = AppSettings();

  AppScreen activeScreen = AppScreen.home;
  StatusFilter statusFilter = StatusFilter.incomplete;
  String? activeProjectId;

  bool _loaded = false;
  bool get loaded => _loaded;

  int _uidCounter = 1;
  String newId(String prefix) =>
      '${prefix}_${_uidCounter++}_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;
    var handled = false;
    if (user != null) {
      // 前回ログイン済みのままアプリを再起動した場合：まずクラウドの
      // データを優先して取り込む（他端末での変更を反映するため）。
      // オフライン等で失敗した場合は、ローカルの保存データにフォールバックする。
      try {
        final cloud = await SyncService.pull(user.uid);
        if (cloud != null) {
          projects = cloud.projects;
          tasks = cloud.tasks;
          settings = cloud.settings;
          settings.googleConnected = true;
          settings.googleEmail = user.email ?? '';
          await PersistenceService.save(projects, tasks, settings);
          handled = true;
        }
      } catch (_) {
        // オフラインなどでクラウド取得に失敗 → ローカルデータで続行する
      }
    }

    if (!handled) {
      final saved = await PersistenceService.load();
      if (saved == null) {
        seedDemoData(this);
        await _persist();
      } else {
        projects = saved.projects;
        tasks = saved.tasks;
        settings = saved.settings;
      }
    }

    // 端末を再起動した場合などに備え、起動時に通知予約を設定内容に
    // 合わせて再適用しておく。
    await NotificationService.scheduleDailyReminder(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      enabled: settings.notifGranted && (settings.notifReminders || settings.notifDeadline),
    );

    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await PersistenceService.save(projects, tasks, settings);
    if (settings.googleConnected) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 通信に時間がかかってもUIをブロックしないよう結果を待たない。
        // オフライン等で失敗しても（次の変更時にまた送られるため）無視してよい。
        SyncService.push(user.uid, projects, tasks, settings).catchError((_) {});
      }
    }
  }

  /// Googleサインインに成功した直後に呼ぶ。クラウドに既存データが
  /// あれば取り込み、無ければ今のローカルデータをクラウドへ送る。
  Future<void> connectGoogle(User user) async {
    final cloud = await SyncService.pull(user.uid);
    if (cloud != null) {
      projects = cloud.projects;
      tasks = cloud.tasks;
      settings = cloud.settings;
    }
    settings.googleConnected = true;
    settings.googleEmail = user.email ?? '';
    await PersistenceService.save(projects, tasks, settings);
    await SyncService.push(user.uid, projects, tasks, settings);
    notifyListeners();
  }

  Future<void> disconnectGoogle() async {
    settings.googleConnected = false;
    settings.googleEmail = '';
    await _persist();
    notifyListeners();
  }

  // ===================== Projects =====================

  Project addProject(
      {required String name, required Color color, DateTime? start, DateTime? end}) {
    final p = Project(id: newId('proj'), name: name, color: color, start: start, end: end);
    projects.add(p);
    _persist();
    notifyListeners();
    return p;
  }

  void updateProject(String id,
      {String? name,
      Color? color,
      DateTime? start,
      DateTime? end,
      bool clearStart = false,
      bool clearEnd = false}) {
    final p = projects.firstWhere((p) => p.id == id);
    if (name != null) p.name = name;
    if (color != null) p.color = color;
    if (clearStart) {
      p.start = null;
    } else if (start != null) {
      p.start = start;
    }
    if (clearEnd) {
      p.end = null;
    } else if (end != null) {
      p.end = end;
    }
    _persist();
    notifyListeners();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    tasks.removeWhere((t) => t.projectId == id);
    if (activeProjectId == id) activeProjectId = null;
    _persist();
    notifyListeners();
  }

  Project? projectById(String? id) {
    if (id == null) return null;
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ===================== Tasks =====================

  Task addTask({
    required String title,
    required String projectId,
    String? group,
    required DateTime due,
    String notes = '',
    bool autoReview = true,
    List<int>? intervals,
  }) {
    final t = Task(
      id: newId('task'),
      title: title,
      projectId: projectId,
      group: group,
      due: due,
      notes: notes,
      autoReview: autoReview,
      intervals: intervals ?? settings.globalIntervals.toList(),
    );
    tasks.add(t);
    _persist();
    notifyListeners();
    return t;
  }

  void updateTask(
    String id, {
    String? title,
    String? projectId,
    String? group,
    bool clearGroup = false,
    DateTime? due,
    String? notes,
    bool? autoReview,
    List<int>? intervals,
  }) {
    final t = tasks.firstWhere((t) => t.id == id);
    if (title != null) t.title = title;
    if (projectId != null) t.projectId = projectId;
    if (clearGroup) {
      t.group = null;
    } else if (group != null) {
      t.group = group;
    }
    if (due != null) t.due = due;
    if (notes != null) t.notes = notes;
    if (autoReview != null) t.autoReview = autoReview;
    if (intervals != null) t.intervals = intervals;
    _persist();
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    _persist();
    notifyListeners();
  }

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// 完了/未完了を切り替える。完了にした瞬間、忘却曲線の間隔にもとづいて
  /// 復習タスクを自動生成する（自動復習がONで、まだ生成していない場合のみ）。
  void toggleComplete(String id) {
    final t = tasks.firstWhere((t) => t.id == id);
    t.completed = !t.completed;
    if (t.completed) {
      t.completedAt = DateTime.now();
      if (t.autoReview &&
          !t.isReview &&
          !t.reviewsGenerated &&
          t.intervals.isNotEmpty) {
        _generateReviews(t);
      }
    }
    _persist();
    notifyListeners();
  }

  void _generateReviews(Task t) {
    for (final d in t.intervals) {
      final title = t.title.startsWith('復習：') ? t.title : '復習：${t.title}';
      tasks.add(Task(
        id: newId('task'),
        title: title,
        projectId: t.projectId,
        group: t.group,
        due: t.completedAt!.add(Duration(days: d)),
        isReview: true,
        parentId: t.id,
        autoReview: false,
        intervals: const [],
      ));
    }
    t.reviewsGenerated = true;
  }

  /// タイマーを停止して記録を保存する（durationSeconds <= 0 のときは何もしない）。
  void commitSession(String taskId, int durationSeconds) {
    if (durationSeconds <= 0) return;
    final t = tasks.firstWhere((t) => t.id == taskId);
    t.sessions.add(StudySession(date: DateTime.now(), durationSeconds: durationSeconds));
    t.timeSpent += durationSeconds;
    _persist();
    notifyListeners();
  }

  // ===================== UI filters / navigation =====================

  void setStatusFilter(StatusFilter f) {
    statusFilter = f;
    notifyListeners();
  }

  void setActiveProject(String? id) {
    activeProjectId = id;
    notifyListeners();
  }

  void setActiveScreen(AppScreen s) {
    activeScreen = s;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    var list =
        tasks.where((t) => activeProjectId == null || t.projectId == activeProjectId).toList();
    switch (statusFilter) {
      case StatusFilter.incomplete:
        list = list.where((t) => t.status == '未完了').toList();
        break;
      case StatusFilter.completed:
        list = list.where((t) => t.status == '完了').toList();
        break;
      case StatusFilter.overdue:
        list = list.where((t) => t.status == '期限切れ').toList();
        break;
      case StatusFilter.reviewOnly:
        list = list.where((t) => t.isReview).toList();
        break;
      case StatusFilter.all:
        break;
    }
    return list;
  }

  // ===================== Settings =====================

  /// settings の任意フィールドを書き換えるための汎用メソッド。
  /// 例: state.updateSettings((s) => s.fontScale = 1.125);
  void updateSettings(void Function(AppSettings s) mutator) {
    mutator(settings);
    _persist();
    notifyListeners();
  }

  void reorderNav(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= settings.navOrder.length) return;
    final item = settings.navOrder.removeAt(oldIndex);
    settings.navOrder.insert(newIndex, item);
    _persist();
    notifyListeners();
  }

  void resetNavOrder() {
    settings.navOrder = ['home', 'calendar', 'stats', 'settings'];
    _persist();
    notifyListeners();
  }
}
