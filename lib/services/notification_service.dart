import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/task.dart';
import '../models/app_settings.dart';
import '../utils/date_utils.dart';

/// 端末への実際の通知（ローカル通知）を管理するサービス。
///
/// 設計：タスク1件につき通知を1件、「期限の何分前に知らせるか」
/// （復習タスクと通常タスクで別々に設定可能）に合わせて予約します。
/// タスクが追加・編集・削除・完了になるたびに、AppState側から
/// このサービスの該当メソッドが呼ばれ、予約が更新されます。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // ここが今回の不具合の本体：これを呼ばないと tz.local が既定でUTCになり、
    // 「期限の15分前」のような計算がすべて日本時間とUTCの差（9時間）だけ
    // ズレてしまう。日本専用アプリなので固定で設定する。
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 許可リクエストは permission_handler 側で行う
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // チャンネルを明示的に作っておく。これをやらないと、最初の通知が
    // 実際に発火するまでチャンネル自体がシステムの「通知」設定に
    // 出てこないため、診断がしづらくなる。
    //
    // ここで resolvePlatformSpecificImplementation が null を返すと、
    // 何も作られないまま黙って次に進んでしまう（?.だと気付けない）ので、
    // 明示的にチェックして、失敗したらその場でわかるようにしている。
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      throw Exception('AndroidFlutterLocalNotificationsPlugin が取得できませんでした（resolvePlatformSpecificImplementation が null）。');
    }
    const channel = AndroidNotificationChannel(
      'studysync_task',
      'タスクの通知',
      description: 'タスクの期限・復習が近づいたときに届く通知です',
      importance: Importance.high,
    );
    await androidPlugin.createNotificationChannel(channel);

    _initialized = true;
  }

  /// タスクのidから、通知用の安定したint IDを作る（正の値に丸める）。
  static int _notificationIdFor(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  /// このタスクの通知を取り消す。
  static Future<void> cancelForTask(String taskId) async {
    await init();
    await _plugin.cancel(id: _notificationIdFor(taskId));
  }

  /// 設定にもとづいて、このタスクの通知を予約し直す
  /// （いったん取り消してから、必要であれば新しく予約する）。
  static Future<void> scheduleForTask(Task task, AppSettings settings) async {
    await init();
    final id = _notificationIdFor(task.id);
    await _plugin.cancel(id: id);

    if (!settings.notifGranted || task.completed) return;

    final enabled = task.isReview ? settings.notifReminders : settings.notifDeadline;
    if (!enabled) return;

    final leadMinutes = task.isReview ? settings.reviewLeadMinutes : settings.deadlineLeadMinutes;
    final notifyAt = task.due.subtract(Duration(minutes: leadMinutes));
    final now = DateTime.now();
    if (notifyAt.isBefore(now.add(const Duration(seconds: 5)))) {
      // 通知予定時刻がもう過ぎている（または近すぎる）場合は予約しない
      return;
    }

    final scheduled = tz.TZDateTime.from(notifyAt, tz.local);
    final due = task.due;
    final dueLabel = '${due.month}/${due.day} ${pad2(due.hour)}:${pad2(due.minute)}';
    final title = task.isReview ? '復習の時間です' : 'もうすぐ期限です';
    final body = task.isReview
        ? '「${task.title}」を $dueLabel までに復習しましょう。'
        : '「${task.title}」の期限は $dueLabel です。';

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'studysync_task',
          'タスクの通知',
          channelDescription: 'タスクの期限・復習が近づいたときに届く通知です',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// 全タスクぶん、通知予約をまとめて作り直す
  /// （アプリ起動時や、通知の設定を変更した直後に呼ぶ）。
  static Future<void> rescheduleAll(List<Task> tasks, AppSettings settings) async {
    await init();
    for (final t in tasks) {
      try {
        await scheduleForTask(t, settings);
      } catch (_) {
        // 1件失敗しても他のタスクの予約は続ける
      }
    }
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
