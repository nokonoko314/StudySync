import 'group_project.dart';

enum WallpaperType { defaultBg, color, image }

/// ダークモードの設定。system: 端末の設定に合わせる。
enum AppThemeMode { system, light, dark }

/// アプリ全体の設定。設定画面の各シートから読み書きされます。
class AppSettings {
  double fontScale; // 0.875=小 / 1.0=標準 / 1.125=大 / 1.25=特大
  List<String> navOrder; // ボトムナビゲーションの並び順
  bool globalAutoReview; // 新規タスク作成時の「自動復習」初期値
  List<int> globalIntervals; // 既定の復習間隔（日数）
  bool googleConnected;
  String googleEmail;
  bool notifGranted;
  bool notifReminders;
  bool notifDeadline;
  int reviewLeadMinutes; // 復習タスク：期限の何分前に知らせるか。既定60分
  int deadlineLeadMinutes; // 通常タスク：期限の何分前に知らせるか。既定180分
  List<GroupProject> knownGroups; // 「プロジェクト」の一覧（名前＋任意の期間）
  String? lastUsedGroup; // 直近のタスクで選んだ「プロジェクト」名。新規タスク作成時の初期値に使う
  int defaultDueHour; // 新規タスク作成時の既定の期限時刻（時）。既定23時
  int defaultDueMinute; // 新規タスク作成時の既定の期限時刻（分）
  WallpaperType wallpaperType;
  int? wallpaperColor; // Color.value
  String? wallpaperImagePath; // ローカルに保存した画像のパス
  List<int> customWallpaperColors; // ユーザーが追加したカスタム壁紙カラー（Color.value）
  int? accentColor; // UIのメインカラー（Color.value）。nullなら既定のインディゴ
  double calendarAgendaScale; // カレンダーの日別タスク表示の大きさ（0.9=小 / 1.0=標準 / 1.15=大）
  String? activeTimerTaskId; // 計測中のタスクID（バックグラウンドでも計測を続けるため保存しておく）
  int? activeTimerStartedAtMs; // 計測を開始した時刻（epoch ms）
  int activeTimerAccumulatedSeconds; // 今回のタイマー実行中に、一時停止までに確定した学習時間の合計（秒）
  int? activeTimerBreakStartedAtMs; // 休憩（一時停止）を始めた時刻（epoch ms）。休憩中でなければnull
  int activeTimerBaselineSeconds; // タイマー開始時点でそのタスクにすでに記録されていた合計時間（秒）。続きから表示するため
  int timerStyleIndex; // 計測画面の時計スタイル（スワイプで選ぶ、0が既定）
  int? timerClockColor; // 時計の色（対応スタイルのみ、Color.value）。nullならスタイルの既定色
  bool durationUseHourMinute; // 学習時間の表示形式。true: 「1時間10分」／false: 「70分」
  AppThemeMode themeMode; // ダークモードの設定
  int weeklyGoalMinutes; // 週の学習時間の目標（分）。0＝未設定
  bool timerAmoledMode; // 計測中の省電力表示（黒背景・白文字のみ）
  int timelineIntervalMinutes; // 統計「日別」タイムラインの目盛りの細かさ（30 or 60）

  AppSettings({
    this.fontScale = 1.0,
    List<String>? navOrder,
    this.globalAutoReview = true,
    List<int>? globalIntervals,
    this.googleConnected = false,
    this.googleEmail = '',
    this.notifGranted = false,
    this.notifReminders = true,
    this.notifDeadline = true,
    this.reviewLeadMinutes = 60,
    this.deadlineLeadMinutes = 180,
    List<GroupProject>? knownGroups,
    this.lastUsedGroup,
    this.defaultDueHour = 23,
    this.defaultDueMinute = 0,
    this.wallpaperType = WallpaperType.defaultBg,
    this.wallpaperColor,
    this.wallpaperImagePath,
    List<int>? customWallpaperColors,
    this.accentColor,
    this.calendarAgendaScale = 1.0,
    this.activeTimerTaskId,
    this.activeTimerStartedAtMs,
    this.activeTimerAccumulatedSeconds = 0,
    this.activeTimerBreakStartedAtMs,
    this.activeTimerBaselineSeconds = 0,
    this.timerStyleIndex = 0,
    this.timerClockColor,
    this.durationUseHourMinute = true,
    this.themeMode = AppThemeMode.system,
    this.weeklyGoalMinutes = 0,
    this.timerAmoledMode = false,
    this.timelineIntervalMinutes = 60,
  })  : navOrder = navOrder ?? ['home', 'calendar', 'stats', 'settings'],
        globalIntervals = globalIntervals ?? [1, 3, 7, 14, 30],
        knownGroups = knownGroups ?? [],
        customWallpaperColors = customWallpaperColors ?? [];

  Map<String, dynamic> toJson() => {
        'fontScale': fontScale,
        'navOrder': navOrder,
        'globalAutoReview': globalAutoReview,
        'globalIntervals': globalIntervals,
        'googleConnected': googleConnected,
        'googleEmail': googleEmail,
        'notifGranted': notifGranted,
        'notifReminders': notifReminders,
        'notifDeadline': notifDeadline,
        'reviewLeadMinutes': reviewLeadMinutes,
        'deadlineLeadMinutes': deadlineLeadMinutes,
        'knownGroups': knownGroups.map((g) => g.toJson()).toList(),
        'lastUsedGroup': lastUsedGroup,
        'defaultDueHour': defaultDueHour,
        'defaultDueMinute': defaultDueMinute,
        'wallpaperType': wallpaperType.index,
        'wallpaperColor': wallpaperColor,
        'wallpaperImagePath': wallpaperImagePath,
        'customWallpaperColors': customWallpaperColors,
        'accentColor': accentColor,
        'calendarAgendaScale': calendarAgendaScale,
        'activeTimerTaskId': activeTimerTaskId,
        'activeTimerStartedAtMs': activeTimerStartedAtMs,
        'activeTimerAccumulatedSeconds': activeTimerAccumulatedSeconds,
        'activeTimerBreakStartedAtMs': activeTimerBreakStartedAtMs,
        'activeTimerBaselineSeconds': activeTimerBaselineSeconds,
        'timerStyleIndex': timerStyleIndex,
        'timerClockColor': timerClockColor,
        'durationUseHourMinute': durationUseHourMinute,
        'themeMode': themeMode.index,
        'weeklyGoalMinutes': weeklyGoalMinutes,
        'timerAmoledMode': timerAmoledMode,
        'timelineIntervalMinutes': timelineIntervalMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        navOrder:
            (json['navOrder'] as List?)?.map((e) => e as String).toList(),
        globalAutoReview: json['globalAutoReview'] as bool? ?? true,
        globalIntervals: (json['globalIntervals'] as List?)
            ?.map((e) => e as int)
            .toList(),
        googleConnected: json['googleConnected'] as bool? ?? false,
        googleEmail: json['googleEmail'] as String? ?? '',
        notifGranted: json['notifGranted'] as bool? ?? false,
        notifReminders: json['notifReminders'] as bool? ?? true,
        notifDeadline: json['notifDeadline'] as bool? ?? true,
        reviewLeadMinutes: json['reviewLeadMinutes'] as int? ?? 60,
        deadlineLeadMinutes: json['deadlineLeadMinutes'] as int? ?? 180,
        knownGroups: _parseKnownGroups(json['knownGroups']),
        lastUsedGroup: json['lastUsedGroup'] as String?,
        defaultDueHour: json['defaultDueHour'] as int? ?? 23,
        defaultDueMinute: json['defaultDueMinute'] as int? ?? 0,
        wallpaperType:
            WallpaperType.values[json['wallpaperType'] as int? ?? 0],
        wallpaperColor: json['wallpaperColor'] as int?,
        wallpaperImagePath: json['wallpaperImagePath'] as String?,
        customWallpaperColors: (json['customWallpaperColors'] as List?)?.map((e) => e as int).toList(),
        accentColor: json['accentColor'] as int?,
        calendarAgendaScale: (json['calendarAgendaScale'] as num?)?.toDouble() ?? 1.0,
        activeTimerTaskId: json['activeTimerTaskId'] as String?,
        activeTimerStartedAtMs: json['activeTimerStartedAtMs'] as int?,
        activeTimerAccumulatedSeconds: json['activeTimerAccumulatedSeconds'] as int? ?? 0,
        activeTimerBreakStartedAtMs: json['activeTimerBreakStartedAtMs'] as int?,
        activeTimerBaselineSeconds: json['activeTimerBaselineSeconds'] as int? ?? 0,
        timerStyleIndex: json['timerStyleIndex'] as int? ?? 0,
        timerClockColor: json['timerClockColor'] as int?,
        durationUseHourMinute: json['durationUseHourMinute'] as bool? ?? true,
        themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 0],
        weeklyGoalMinutes: json['weeklyGoalMinutes'] as int? ?? 0,
        timerAmoledMode: json['timerAmoledMode'] as bool? ?? false,
        timelineIntervalMinutes: json['timelineIntervalMinutes'] as int? ?? 60,
      );
}

/// 以前のバージョン（`knownGroups` が単なる名前の配列だった頃）のデータでも
/// 問題なく読み込めるよう、要素が文字列でもオブジェクトでも対応する。
List<GroupProject>? _parseKnownGroups(dynamic raw) {
  if (raw is! List) return null;
  return raw.map((e) {
    if (e is String) return GroupProject(name: e);
    return GroupProject.fromJson(Map<String, dynamic>.from(e as Map));
  }).toList();
}
