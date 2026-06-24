import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// 端末への実際の通知（ローカル通知）を管理するサービス。
/// 「毎日この時刻に知らせる」という、設定でユーザーが選んだ通知時刻に
/// 合わせた繰り返し通知を1件スケジュールします。
///
/// permission_handler でOSの通知許可状態を確認・表示する一方、
/// 実際に通知を「送る」のはこのサービス（flutter_local_notifications）が
/// 担当します。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int _dailyReminderId = 1001;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 許可リクエストは permission_handler 側で行う
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// 毎日 [hour]:[minute] に繰り返し通知を送るよう設定する。
  /// [enabled] が false の場合は、既存の予約をキャンセルするだけ。
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool enabled,
  }) async {
    await init();
    await _plugin.cancel(id: _dailyReminderId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'StudySync',
      body: '今日の学習タスクと復習を確認しましょう。',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'studysync_daily',
          '学習リマインダー',
          channelDescription: '設定した時刻に毎日届く学習リマインダー通知です',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}