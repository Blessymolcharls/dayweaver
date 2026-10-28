import '../domain/activity.dart';

abstract class ActivityRepository {
  /// Watches all activities scheduled on [date], ordered by startMinute ascending.
  Stream<List<Activity>> watchActivitiesForDate(DateTime date);

  /// Gets all activities scheduled on [date], ordered by startMinute ascending.
  Future<List<Activity>> getActivitiesForDate(DateTime date);

  /// Gets a single activity by [id].
  Future<Activity?> getActivityById(String id);

  /// Inserts or updates an activity.
  Future<void> saveActivity(Activity activity);

  /// Deletes an activity by [id].
  Future<void> deleteActivity(String id);

  /// Toggles completion state for an activity.
  Future<void> toggleCompletion(String id, bool isCompleted);

  /// Gets total count of activities across all dates.
  Future<int> countActivities();
}
