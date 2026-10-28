import '../domain/activity.dart';
import '../domain/batch_operation_result.dart';
import '../domain/conflict_strategy.dart';
import '../domain/routine_template.dart';
import '../domain/routine_template_block.dart';

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

  /// Duplicates an existing activity.
  /// If [targetDate] or [targetStartMinute] are specified, they are applied.
  Future<Activity> duplicateActivity(
    String id, {
    DateTime? targetDate,
    int? targetStartMinute,
  });

  /// Moves an activity to a new date and/or time span.
  Future<void> moveActivity(
    String id, {
    required DateTime newDate,
    required int newStartMinute,
    required int newEndMinute,
  });

  /// Returns normalized dates within the range [startRange] to [endRange] that contain activities.
  Future<Set<DateTime>> getDatesWithActivities(
    DateTime startRange,
    DateTime endRange,
  );

  /// Routine Template operations
  Stream<List<RoutineTemplate>> watchTemplates();
  Future<List<RoutineTemplate>> getTemplates();
  Future<RoutineTemplate?> getTemplateById(String id);
  Future<void> saveTemplate(RoutineTemplate template);
  Future<void> deleteTemplate(String id);
  Future<void> saveTemplateBlock(RoutineTemplateBlock block);
  Future<void> deleteTemplateBlock(String blockId);
  Future<int> countTemplates();

  /// Applies a routine template to a specific date using [conflictStrategy].
  /// Runs inside a database transaction to ensure atomicity.
  Future<BatchOperationResult> applyTemplateToDate({
    required String templateId,
    required DateTime date,
    required ConflictStrategy conflictStrategy,
  });

  /// Copies an entire schedule from [fromDate] to [toDate] using [conflictStrategy].
  /// Runs inside a database transaction to ensure atomicity.
  Future<BatchOperationResult> copySchedule({
    required DateTime fromDate,
    required DateTime toDate,
    required ConflictStrategy conflictStrategy,
  });
}
