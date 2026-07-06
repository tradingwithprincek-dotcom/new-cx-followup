import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the local "Reminder" notification for a Follow-up and cancels
/// it when the follow-up is completed/rescheduled/deleted. This is the
/// "Local Notifications" + "Reminder Badge" piece of Milestone 3's spec.
///
/// Push notifications ("Push Notifications Ready") are intentionally NOT
/// wired to a real backend here — there is no push infra yet (FCM project,
/// device-token registration endpoint) and that's out of scope until the
/// WhatsApp/Calling backends land in Milestone 4/5. `NotificationService` is
/// the single seam a future `registerPushToken()` / remote-trigger call
/// would plug into, so screens never talk to flutter_local_notifications
/// directly.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      'followup_reminders',
      'Follow-up Reminders',
      description: 'Reminders for scheduled customer follow-ups',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// One notification id per follow-up so reschedule/cancel can target it
  /// precisely — Dart's hashCode on a UUID string is stable and collision-safe
  /// enough for this per-device, per-rep notification set.
  int _notificationId(String followUpId) => followUpId.hashCode & 0x7fffffff;

  Future<void> scheduleFollowUpReminder({
    required String followUpId,
    required String customerName,
    required String typeLabel,
    required DateTime reminderAt,
  }) async {
    await init();
    if (reminderAt.isBefore(DateTime.now())) return; // don't schedule in the past

    await _plugin.zonedSchedule(
      _notificationId(followUpId),
      '$typeLabel follow-up due',
      'Reach out to $customerName',
      tz.TZDateTime.from(reminderAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'followup_reminders',
          'Follow-up Reminders',
          channelDescription: 'Reminders for scheduled customer follow-ups',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFollowUpReminder(String followUpId) async {
    await init();
    await _plugin.cancel(_notificationId(followUpId));
  }
}
