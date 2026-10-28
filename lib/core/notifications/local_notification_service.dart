import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/schedule/domain/time_utils.dart';
import '../../features/schedule/domain/activity.dart';
import 'notification_service.dart';

/// Concrete implementation of [NotificationService] using flutter_local_notifications
/// and timezone.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  static const String channelId = 'dayweaver_activity_reminders';
  static const String channelName = 'Activity Reminders';
  static const String channelDescription =
      'Timely alerts and reminders for your planned Dayweaver schedule.';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();

      // 2. Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Platform init settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // 4. Create Android high-importance notification channel
      final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidImpl.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e, st) {
      debugPrint('Failed to initialize LocalNotificationService: $e\n$st');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl == null) return false;

      final bool? granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImpl == null) return false;

      final bool? enabled = await androidImpl.areNotificationsEnabled();
      return enabled ?? false;
    } catch (e) {
      debugPrint('Error checking notification permission status: $e');
      return false;
    }
  }

  @override
  int getNotificationId(String activityId) {
    // Deterministic 31-bit positive integer hash derived from persistent UUID
    return activityId.hashCode & 0x7FFFFFFF;
  }

  @override
  Future<bool> scheduleActivityReminder(Activity activity) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (activity.reminderOffsetMinutes == null) {
      await cancelActivityReminder(activity.id);
      return false;
    }

    if (activity.isCompleted) {
      await cancelActivityReminder(activity.id);
      return false;
    }

    final int scheduledMinuteOfDay =
        activity.startMinute - activity.reminderOffsetMinutes!;

    final DateTime targetDateTime = DateTime(
      activity.date.year,
      activity.date.month,
      activity.date.day,
      scheduledMinuteOfDay ~/ 60,
      scheduledMinuteOfDay % 60,
    );

    if (targetDateTime.isBefore(DateTime.now())) {
      await cancelActivityReminder(activity.id);
      return false;
    }

    final int id = getNotificationId(activity.id);
    final String startTimeStr = TimeUtils.formatMinutes(activity.startMinute);
    final String endTimeStr = TimeUtils.formatMinutes(activity.endMinute);

    final String notificationTitle = activity.title;
    final String notificationBody = activity.reminderOffsetMinutes == 0
        ? 'Starting now ($startTimeStr - $endTimeStr)'
        : 'Starts in ${activity.reminderOffsetMinutes}m ($startTimeStr - $endTimeStr)';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          ticker: 'Dayweaver reminder',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      targetDateTime,
      tz.local,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: notificationTitle,
        body: notificationBody,
        scheduledDate: tzScheduledTime,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: activity.id,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to schedule reminder for activity ${activity.id}: $e');
      return false;
    }
  }

  @override
  Future<void> cancelActivityReminder(String activityId) async {
    try {
      final int id = getNotificationId(activityId);
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Failed to cancel reminder for activity $activityId: $e');
    }
  }

  @override
  Future<int> rescheduleAllReminders(List<Activity> upcomingActivities) async {
    if (!_isInitialized) {
      await initialize();
    }

    int scheduledCount = 0;
    for (final Activity activity in upcomingActivities) {
      final bool scheduled = await scheduleActivityReminder(activity);
      if (scheduled) scheduledCount++;
    }
    return scheduledCount;
  }
}
