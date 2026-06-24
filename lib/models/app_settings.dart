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
  int reminderHour; // 通知時刻（時）。既定 20:00
  int reminderMinute; // 通知時刻（分）
  WallpaperType wallpaperType;
  int? wallpaperColor; // Color.value
  String? wallpaperImagePath; // ローカルに保存した画像のパス

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
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.wallpaperType = WallpaperType.defaultBg,
    this.wallpaperColor,
    this.wallpaperImagePath,
  })  : navOrder = navOrder ?? ['home', 'calendar', 'stats', 'settings'],
        globalIntervals = globalIntervals ?? [1, 3, 7, 14, 30];

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
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'wallpaperType': wallpaperType.index,
        'wallpaperColor': wallpaperColor,
        'wallpaperImagePath': wallpaperImagePath,
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
        reminderHour: json['reminderHour'] as int? ?? 20,
        reminderMinute: json['reminderMinute'] as int? ?? 0,
        wallpaperType:
            WallpaperType.values[json['wallpaperType'] as int? ?? 0],
        wallpaperColor: json['wallpaperColor'] as int?,
        wallpaperImagePath: json['wallpaperImagePath'] as String?,
      );
}
