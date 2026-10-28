import '../../features/schedule/domain/activity.dart';

/// Abstract service contract for scheduling and managing local activity reminders.
abstract class NotificationService {
  /// Initializes notification plugin, channels, and timezone data.
  Future<void> initialize();

  /// Requests notification permissions (Android 13+ POST_NOTIFICATIONS).
  Future<bool> requestPermissions();

  /// Checks if notification permissions are currently granted.
  Future<bool> areNotificationsEnabled();

  /// Schedules or updates a reminder for an activity if it has a reminder offset
  /// and is not in the past or completed.
  Future<bool> scheduleActivityReminder(Activity activity);

  /// Cancels any scheduled reminder for the specified activity.
  Future<void> cancelActivityReminder(String activityId);

  /// Synchronizes / rebuilds reminders for all upcoming active activities.
  Future<int> rescheduleAllReminders(List<Activity> upcomingActivities);

  /// Returns a deterministic 31-bit integer ID for the given activity UUID.
  int getNotificationId(String activityId);
}
