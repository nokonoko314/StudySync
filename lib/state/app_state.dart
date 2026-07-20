import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../models/group_project.dart';
import '../services/persistence_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/seed_data.dart';
import '../app_theme.dart';
import '../utils/date_utils.dart';

enum AppScreen { home, calendar, stats, settings }

enum StatusFilter { incomplete, completed, overdue, reviewOnly, all, byDeadline }

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
      case StatusFilter.byDeadline:
        return '締切が近い順';
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
  /// ドロワーの「プロジェクト」セクションで選んだ絞り込み（旧グループ名）。
  /// 教科の絞り込み（activeProjectId）とは同時に1つだけ有効（片方を選ぶともう片方は解除される）。
  String? activeGroupTag;

  bool _loaded = false;
  bool get loaded => _loaded;

  int _uidCounter = 1;
  String newId(String prefix) =>
      '${prefix}_${_uidCounter++}_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> load() async {
    try {
      await _doLoad().timeout(const Duration(seconds: 20));
    } on TimeoutException catch (_) {
      debugPrint('[AppState.load] timed out after 20s — continuing with whatever is available');
    } catch (e, st) {
      debugPrint('[AppState.load] unexpected error: $e\n$st');
    } finally {
      if (projects.isEmpty && tasks.isEmpty) {
        // ここまでで何も読み込めていなければ、最後の手段としてデモデータを入れる
        seedDemoData(this);
      }
      // 保存されているUIカラー（アクセントカラー）があれば反映する。
      if (settings.accentColor != null) {
        AppColors.setAccent(Color(settings.accentColor!));
      }
      // 学習時間の表示形式（分のみ／時間＋分）を反映する。
      TimeDisplaySettings.useHourMinute = settings.durationUseHourMinute;
      // ダークモードの設定を反映する。
      applyThemeMode();
      // ここを必ず通すことで、どこかで失敗・タイムアウトしてもアプリが
      // 「読み込み中」のまま固まらないようにしている。
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _doLoad() async {
    final user = FirebaseAuth.instance.currentUser;
    var handled = false;
    if (user != null) {
      // 前回ログイン済みのままアプリを再起動した場合：まずクラウドの
      // データを優先して取り込む（他端末での変更を反映するため）。
      // オフライン等で失敗した場合は、ローカルの保存データにフォールバックする。
      try {
        final cloud = await SyncService.pull(user.uid).timeout(const Duration(seconds: 8));
        if (cloud != null) {
          projects = cloud.projects;
          tasks = cloud.tasks;
          settings = cloud.settings;
          settings.googleConnected = true;
          settings.googleEmail = user.email ?? '';
          await PersistenceService.save(projects, tasks, settings);
          handled = true;
        }
      } catch (e) {
        debugPrint('[AppState.load] cloud pull failed: $e');
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

    // 通知の許可状態は、システムの設定画面から直接許可された場合でも
    // 正しく反映されるよう、起動時に実際のOS側の状態と同期しておく。
    try {
      await syncNotifPermission();
    } catch (e) {
      debugPrint('[AppState.load] notif permission sync failed: $e');
    }

    // 端末を再起動した場合などに備え、起動時に通知予約を設定内容に
    // 合わせて再適用しておく。失敗しても起動自体は止めない。
    try {
      await NotificationService.rescheduleAll(tasks, settings).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[AppState.load] notification schedule failed: $e');
    }
  }

  /// OS側の実際の通知許可状態を確認し、settings.notifGranted を同期する。
  /// 「アプリ内のスイッチではなく、端末の設定から直接許可した」場合にも
  /// 正しく反映されるようにするためのもの。
  Future<bool> syncNotifPermission() async {
    final status = await Permission.notification.status;
    if (settings.notifGranted != status.isGranted) {
      settings.notifGranted = status.isGranted;
      _persist();
    }
    return status.isGranted;
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
    if (settings.accentColor != null) AppColors.setAccent(Color(settings.accentColor!));
    TimeDisplaySettings.useHourMinute = settings.durationUseHourMinute;
    applyThemeMode();
    await PersistenceService.save(projects, tasks, settings);
    await SyncService.push(user.uid, projects, tasks, settings);
    notifyListeners();
  }

  /// 連携を解除する。
  ///
  /// これまでは解除してもローカルの表示がそのまま残ってしまい、別の
  /// Googleアカウントで再連携した際に「前のアカウントのタスクが
  /// 残って見える」不具合があった（クラウド側に新規アカウントの
  /// データが無い場合、ローカルのデータをそのまま新アカウントに
  /// 紐づけてしまっていたため）。
  ///
  /// このアカウントの最新データは、直前までの操作で都度クラウドへ
  /// 送信済みなので消えない。解除時はローカルの表示だけを
  /// 「初期状態（デモデータ）」に戻すことで、次に別アカウントで
  /// 連携したときに正しくそのアカウントのデータだけが反映されるようにする。
  Future<void> disconnectGoogle() async {
    final keepWallpaperType = settings.wallpaperType;
    final keepWallpaperColor = settings.wallpaperColor;
    final keepWallpaperImagePath = settings.wallpaperImagePath;
    final keepCustomWallpaperColors = settings.customWallpaperColors;
    final keepFontScale = settings.fontScale;
    final keepNavOrder = settings.navOrder;
    final keepNotifGranted = settings.notifGranted;

    projects = [];
    tasks = [];
    settings = AppSettings()
      ..wallpaperType = keepWallpaperType
      ..wallpaperColor = keepWallpaperColor
      ..wallpaperImagePath = keepWallpaperImagePath
      ..customWallpaperColors = keepCustomWallpaperColors
      ..fontScale = keepFontScale
      ..navOrder = keepNavOrder
      ..notifGranted = keepNotifGranted;
    seedDemoData(this);

    await _persist();
    notifyListeners();
  }

  // ===================== Projects =====================

  Project addProject({required String name, required Color color}) {
    final p = Project(id: newId('proj'), name: name, color: color);
    projects.add(p);
    _persist();
    notifyListeners();
    return p;
  }

  void updateProject(String id, {String? name, Color? color}) {
    final p = projects.firstWhere((p) => p.id == id);
    if (name != null) p.name = name;
    if (color != null) p.color = color;
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
    if (group != null) registerGroup(group);
    settings.lastUsedGroup = group;
    _persist();
    NotificationService.scheduleForTask(t, settings).catchError((_) {});
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
      registerGroup(group);
      settings.lastUsedGroup = group;
    }
    if (due != null) t.due = due;
    if (notes != null) t.notes = notes;
    if (autoReview != null) t.autoReview = autoReview;
    if (intervals != null) t.intervals = intervals;
    _persist();
    NotificationService.scheduleForTask(t, settings).catchError((_) {});
    notifyListeners();
  }

  void deleteTask(String id) {
    NotificationService.cancelForTask(id).catchError((_) {});
    // 元のタスクを消したら、そこから生成された復習タスクも一緒に消す
    final children = tasks.where((t) => t.parentId == id).map((t) => t.id).toList();
    for (final childId in children) {
      NotificationService.cancelForTask(childId).catchError((_) {});
    }
    tasks.removeWhere((t) => t.id == id || t.parentId == id);
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
    NotificationService.scheduleForTask(t, settings).catchError((_) {});
    notifyListeners();
  }

  void _generateReviews(Task t) {
    for (final d in t.intervals) {
      final title = t.title.startsWith('復習：') ? t.title : '復習：${t.title}';
      final review = Task(
        id: newId('task'),
        title: title,
        projectId: t.projectId,
        group: t.group,
        due: t.completedAt!.add(Duration(days: d)),
        isReview: true,
        parentId: t.id,
        autoReview: false,
        intervals: const [],
      );
      tasks.add(review);
      NotificationService.scheduleForTask(review, settings).catchError((_) {});
    }
    t.reviewsGenerated = true;
  }

  // ── 学習タイマー（バックグラウンドでも計測を続ける） ──────────────
  //
  // Dartの Timer/Stopwatch はアプリがバックグラウンドに回ると一時停止して
  // しまうことがあるため、「開始した時刻（壁時計時間）」だけを保存しておき、
  // 経過時間は常に「今の時刻 - 開始時刻」で計算する方式にしている。
  // これなら、アプリを閉じても・再起動しても、開始時刻さえ残っていれば
  // 正しい経過時間を復元できる。

  String? get activeTimerTaskId => settings.activeTimerTaskId;

  DateTime? get activeTimerStartedAt =>
      settings.activeTimerStartedAtMs != null ? DateTime.fromMillisecondsSinceEpoch(settings.activeTimerStartedAtMs!) : null;

  int get activeTimerElapsedSeconds {
    final started = activeTimerStartedAt;
    if (started == null) return 0;
    final diff = DateTime.now().difference(started).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  /// 指定したタスクの計測を開始する。既に別のタスクを計測中なら、
  /// そちらは先に確定保存してから切り替える。
  void startTimer(String taskId) {
    if (settings.activeTimerTaskId != null && settings.activeTimerTaskId != taskId) {
      stopTimer();
    }
    settings.activeTimerTaskId = taskId;
    settings.activeTimerStartedAtMs = DateTime.now().millisecondsSinceEpoch;
    _persist();
    notifyListeners();
  }

  /// 計測中のタイマーを停止し、経過時間を学習記録として確定保存する。
  void stopTimer() {
    final taskId = settings.activeTimerTaskId;
    final seconds = activeTimerElapsedSeconds;
    settings.activeTimerTaskId = null;
    settings.activeTimerStartedAtMs = null;
    if (taskId != null && seconds > 0 && tasks.any((t) => t.id == taskId)) {
      commitSession(taskId, seconds);
    } else {
      _persist();
      notifyListeners();
    }
  }

  /// タイマーを停止して記録を保存する（durationSeconds <= 0 のときは何もしない）。
  void commitSession(String taskId, int durationSeconds) {
    if (durationSeconds <= 0) return;
    final t = tasks.firstWhere((t) => t.id == taskId);
    t.sessions.add(StudySession(id: newId('sess'), date: DateTime.now(), durationSeconds: durationSeconds));
    t.timeSpent += durationSeconds;
    _persist();
    notifyListeners();
  }

  /// 学習記録（タイマーのセッション）を1件削除する。
  /// 間違って計測してしまった記録を取り消すために使う。
  void deleteSession(String taskId, String sessionId) {
    final t = tasks.firstWhere((t) => t.id == taskId);
    final session = t.sessions.firstWhere((s) => s.id == sessionId, orElse: () => StudySession(id: '', date: DateTime.now(), durationSeconds: 0));
    if (session.id.isEmpty) return;
    t.sessions.removeWhere((s) => s.id == sessionId);
    t.timeSpent = (t.timeSpent - session.durationSeconds).clamp(0, 1 << 31);
    _persist();
    notifyListeners();
  }

  /// 記録ミスの修正用：学習記録（セッション）の開始・終了時刻を直接編集する。
  /// タスクの合計学習時間（timeSpent）も差分をあわせて更新する。
  void editSession(String taskId, String sessionId, {required DateTime newStart, required DateTime newEnd}) {
    final t = tasks.firstWhere((t) => t.id == taskId);
    final idx = t.sessions.indexWhere((s) => s.id == sessionId);
    if (idx == -1) return;
    final newDuration = newEnd.difference(newStart).inSeconds;
    if (newDuration <= 0) return;
    final oldDuration = t.sessions[idx].durationSeconds;
    t.sessions[idx] = StudySession(id: sessionId, date: newEnd, durationSeconds: newDuration);
    t.timeSpent = (t.timeSpent - oldDuration + newDuration).clamp(0, 1 << 31);
    _persist();
    notifyListeners();
  }



  void setStatusFilter(StatusFilter f) {
    statusFilter = f;
    notifyListeners();
  }

  void setActiveProject(String? id) {
    activeProjectId = id;
    if (id != null) activeGroupTag = null;
    notifyListeners();
  }

  void setActiveGroupTag(String? tag) {
    activeGroupTag = tag;
    if (tag != null) activeProjectId = null;
    notifyListeners();
  }

  void setActiveScreen(AppScreen s) {
    activeScreen = s;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    var list = tasks.where((t) {
      if (activeProjectId != null && t.projectId != activeProjectId) return false;
      if (activeGroupTag != null && t.group != activeGroupTag) return false;
      return true;
    }).toList();
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
      case StatusFilter.byDeadline:
        list = list.where((t) => !t.completed).toList();
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

  /// 通知関連の設定（許可状態・リード時間など）を変更した直後に呼ぶ。
  /// 全タスクの通知予約をその場で作り直す。
  Future<void> rescheduleAllNotifications() async {
    try {
      await NotificationService.rescheduleAll(tasks, settings);
    } catch (e) {
      debugPrint('[AppState.rescheduleAllNotifications] failed: $e');
    }
  }

  void reorderNav(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= settings.navOrder.length) return;
    final item = settings.navOrder.removeAt(oldIndex);
    settings.navOrder.insert(newIndex, item);
    _persist();
    notifyListeners();
  }

  /// UIのメインカラー（アクセントカラー）を変更する。
  void setAccentColor(Color color) {
    settings.accentColor = color.value;
    AppColors.setAccent(color);
    _persist();
    notifyListeners();
  }

  /// UIのメインカラーを既定の色（インディゴ）に戻す。
  void resetAccentColor() {
    settings.accentColor = null;
    AppColors.setAccent(const Color(0xFF423E99));
    _persist();
    notifyListeners();
  }

  /// カレンダーの日別タスク表示の大きさ（開閉ヘッダー・カード）を変更する。
  void setCalendarAgendaScale(double scale) {
    settings.calendarAgendaScale = scale;
    _persist();
    notifyListeners();
  }

  /// 学習時間の表示形式を変更する（true: 「1時間10分」／false: 「70分」）。
  void setDurationUseHourMinute(bool useHourMinute) {
    settings.durationUseHourMinute = useHourMinute;
    TimeDisplaySettings.useHourMinute = useHourMinute;
    _persist();
    notifyListeners();
  }

  /// 現在の設定（端末に合わせる／常にライト／常にダーク）から、
  /// 実際にダーク配色にするかどうかを判定して反映する。
  /// 「端末に合わせる」のときは、その時点のOSの明暗設定を見る。
  void applyThemeMode() {
    final dark = switch (settings.themeMode) {
      AppThemeMode.dark => true,
      AppThemeMode.light => false,
      AppThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    };
    if (AppColors.isDark == dark) return;
    AppColors.setDark(dark);
    // indigoSoft は明暗によって計算し直す必要があるため、同じ色で再計算する。
    AppColors.setAccent(AppColors.indigo);
  }

  /// ダークモードの設定を変更する。
  void setThemeMode(AppThemeMode mode) {
    settings.themeMode = mode;
    applyThemeMode();
    _persist();
    notifyListeners();
  }

  /// 端末側の明暗設定が変わったときに呼ばれる（「端末に合わせる」時のみ意味がある）。
  void refreshSystemBrightness() {
    if (settings.themeMode != AppThemeMode.system) return;
    applyThemeMode();
    notifyListeners();
  }

  /// 週の学習時間の目標（分）を変更する。0にすると目標なしになる。
  void setWeeklyGoalMinutes(int minutes) {
    settings.weeklyGoalMinutes = minutes;
    _persist();
    notifyListeners();
  }

  void resetNavOrder() {
    settings.navOrder = ['home', 'calendar', 'stats', 'settings'];
    _persist();
    notifyListeners();
  }

  /// ドロワーの「教科」を長押しドラッグで並び替えたときに呼ばれる。
  void reorderProjects(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 || oldIndex >= projects.length) return;
    if (newIndex < 0 || newIndex >= projects.length) return;
    final item = projects.removeAt(oldIndex);
    projects.insert(newIndex, item);
    _persist();
    notifyListeners();
  }

  /// 「プロジェクト」名（旧グループ）を「使ったことがある候補」として記録する。
  /// 一度使えば、別のタスク・別の科目でも次から候補に出てくるようになる。
  void registerGroup(String group) {
    final trimmed = group.trim();
    if (trimmed.isEmpty || settings.knownGroups.any((g) => g.name == trimmed)) return;
    settings.knownGroups.add(GroupProject(name: trimmed));
    _persist();
    notifyListeners();
  }

  GroupProject? groupProjectByName(String name) {
    for (final g in settings.knownGroups) {
      if (g.name == name) return g;
    }
    return null;
  }

  /// プロジェクトの期間（開始日・終了日、どちらも任意）を設定する。
  /// 終了日を設定しておくと、期間が終わったあとも一覧の「過去のプロジェクト」
  /// から選んで振り返れるようになる。
  void setGroupPeriod(String name, {DateTime? startDate, DateTime? endDate}) {
    final g = groupProjectByName(name);
    if (g == null) return;
    g.startDate = startDate;
    g.endDate = endDate;
    _persist();
    notifyListeners();
  }

  void removeKnownGroup(String group) {
    settings.knownGroups.removeWhere((g) => g.name == group);
    if (settings.lastUsedGroup == group) settings.lastUsedGroup = null;
    _persist();
    notifyListeners();
  }

  /// 「プロジェクト」名（旧グループ）を変更し、それを使っている全タスクにも反映する。
  void renameKnownGroup(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    final idx = settings.knownGroups.indexWhere((g) => g.name == oldName);
    if (idx == -1) return;
    if (settings.knownGroups.any((g) => g.name == trimmed)) {
      // 既に同名のものがある場合は、統合する（重複させない）
      settings.knownGroups.removeAt(idx);
    } else {
      settings.knownGroups[idx].name = trimmed;
    }
    for (final t in tasks) {
      if (t.group == oldName) t.group = trimmed;
    }
    if (settings.lastUsedGroup == oldName) settings.lastUsedGroup = trimmed;
    _persist();
    notifyListeners();
  }

  /// 新規タスク作成時の既定の期限日時（今日の、設定された既定時刻）。
  DateTime defaultDueDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, settings.defaultDueHour, settings.defaultDueMinute);
  }
}
