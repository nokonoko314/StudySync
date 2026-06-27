enum WallpaperType { defaultBg, color, image }

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
  List<String> knownGroups; // 一度使った「プロジェクト」名を覚えておき、次回から候補として出す
  int defaultDueHour; // 新規タスク作成時の既定の期限時刻（時）。既定23時
  int defaultDueMinute; // 新規タスク作成時の既定の期限時刻（分）
  WallpaperType wallpaperType;
  int? wallpaperColor; // Color.value
  String? wallpaperImagePath; // ローカルに保存した画像のパス
  List<int> customWallpaperColors; // ユーザーが追加したカスタム壁紙カラー（Color.value）

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
    List<String>? knownGroups,
    this.defaultDueHour = 23,
    this.defaultDueMinute = 0,
    this.wallpaperType = WallpaperType.defaultBg,
    this.wallpaperColor,
    this.wallpaperImagePath,
    List<int>? customWallpaperColors,
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
        'knownGroups': knownGroups,
        'defaultDueHour': defaultDueHour,
        'defaultDueMinute': defaultDueMinute,
        'wallpaperType': wallpaperType.index,
        'wallpaperColor': wallpaperColor,
        'wallpaperImagePath': wallpaperImagePath,
        'customWallpaperColors': customWallpaperColors,
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
        knownGroups: (json['knownGroups'] as List?)?.map((e) => e as String).toList(),
        defaultDueHour: json['defaultDueHour'] as int? ?? 23,
        defaultDueMinute: json['defaultDueMinute'] as int? ?? 0,
        wallpaperType:
            WallpaperType.values[json['wallpaperType'] as int? ?? 0],
        wallpaperColor: json['wallpaperColor'] as int?,
        wallpaperImagePath: json['wallpaperImagePath'] as String?,
        customWallpaperColors: (json['customWallpaperColors'] as List?)?.map((e) => e as int).toList(),
      );
}
