import '../domain/goal.dart';
import '../domain/goal_milestone.dart';
import '../domain/goal_progress_update.dart';
import '../domain/goal_status.dart';

abstract class GoalRepository {
  /// Stream of goals, optionally filtered by status.
  Stream<List<Goal>> watchGoals({GoalStatus? filterStatus});

  /// Future of goals, optionally filtered by status.
  Future<List<Goal>> getGoals({GoalStatus? filterStatus});

  /// Gets a single goal with milestones and linked activities.
  Future<Goal?> getGoalById(String id);

  /// Saves (creates or updates) a goal.
  Future<void> saveGoal(Goal goal);

  /// Deletes a goal and its associated milestones, progress updates, and activity links.
  Future<void> deleteGoal(String id);

  /// Updates goal status (e.g. active, paused, completed, archived).
  Future<void> updateGoalStatus(String id, GoalStatus status);

  /// Records a manual progress update.
  /// If [isIncremental] is true, [changeAmount] is added to current value;
  /// if false, [changeAmount] sets the new total value.
  Future<void> recordProgressUpdate({
    required String goalId,
    required double changeAmount,
    required bool isIncremental,
    String? note,
  });

  /// Milestones
  Stream<List<GoalMilestone>> watchMilestones(String goalId);
  Future<List<GoalMilestone>> getMilestones(String goalId);
  Future<void> saveMilestone(GoalMilestone milestone);
  Future<void> deleteMilestone(String milestoneId);
  Future<void> toggleMilestone(String milestoneId, bool isCompleted);

  /// Progress Updates
  Stream<List<GoalProgressUpdate>> watchProgressUpdates(String goalId);
  Future<List<GoalProgressUpdate>> getProgressUpdates(String goalId);

  /// Activity-Goal links
  Future<void> linkActivityToGoal(String activityId, String goalId);
  Future<void> unlinkActivityFromGoal(String activityId, String goalId);
  Future<List<String>> getLinkedGoalIdsForActivity(String activityId);
  Future<List<String>> getLinkedActivityIdsForGoal(String goalId);
  Future<List<Goal>> getLinkedGoalsForActivity(String activityId);
  Stream<List<Goal>> watchGoalsForActivity(String activityId);

  /// Insights & metrics queries
  Future<int> getActiveGoalsCount();
  Future<int> getCompletedGoalsCountForPeriod(DateTime start, DateTime end);
  Future<List<Goal>> getGoalsApproachingDeadline(DateTime deadlineLimit);
  Future<int> getProgressUpdatesCountForPeriod(DateTime start, DateTime end);
}
