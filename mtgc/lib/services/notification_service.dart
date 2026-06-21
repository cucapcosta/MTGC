import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// One scheduled reminder: a delay from "now" plus its text.
class ReminderNotification {
  const ReminderNotification(this.id, this.delay, this.title, this.body);

  final int id;
  final Duration delay;
  final String title;
  final String body;
}

/// The reminders to fire after a pack is opened. Pure: fixed offsets/text,
/// applied to the current time by [NotificationService.scheduleReminders].
List<ReminderNotification> reminderPlan() => const [
      ReminderNotification(
          0, Duration(minutes: 5), 'MTG Collector', 'Seus boosters esperam! 🎴'),
      ReminderNotification(
          1, Duration(minutes: 10), 'MTG Collector', 'Hora de abrir mais um pacote!'),
    ];

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'booster_reminders';
  static const _channelName = 'Lembretes de booster';

  /// Initialize the plugin and request notification permission. Call once from
  /// main() before runApp.
  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't prompt during init; we request explicitly below so the permission
    // ask happens at launch on both platforms.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Cancel any pending reminders and schedule a fresh +5/+10 min pair.
  static Future<void> scheduleReminders() async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    for (final r in reminderPlan()) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: now.add(r.delay),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
