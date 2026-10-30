import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../schedule/presentation/activity_providers.dart';
import '../data/drift_goal_repository.dart';
import '../data/goal_repository.dart';
import '../domain/goal.dart';
import '../domain/goal_milestone.dart';
import '../domain/goal_progress_update.dart';
import '../domain/goal_status.dart';

/// Goal repository provider
final Provider<GoalRepository> goalRepositoryProvider =
    Provider<GoalRepository>((Ref ref) {
      final AppDatabase db = ref.watch(appDatabaseProvider);
      return DriftGoalRepository(db);
    });

/// Filter status provider (null for All)
final StateProvider<GoalStatus?> goalFilterStatusProvider =
    StateProvider<GoalStatus?>((Ref ref) => null);

/// Search query provider
final StateProvider<String> goalSearchQueryProvider = StateProvider<String>(
  (Ref ref) => '',
);

/// Stream of all goals
final StreamProvider<List<Goal>> allGoalsStreamProvider =
    StreamProvider<List<Goal>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      return repo.watchGoals();
    });

/// Stream of filtered & searched goals
final Provider<List<Goal>> filteredGoalsProvider = Provider<List<Goal>>((
  Ref ref,
) {
  final AsyncValue<List<Goal>> goalsAsync = ref.watch(allGoalsStreamProvider);
  final List<Goal> allGoals = goalsAsync.valueOrNull ?? [];
  final GoalStatus? statusFilter = ref.watch(goalFilterStatusProvider);
  final String searchQuery = ref
      .watch(goalSearchQueryProvider)
      .trim()
      .toLowerCase();

  return allGoals.where((Goal g) {
    if (statusFilter != null && g.status != statusFilter) {
      return false;
    }
    if (searchQuery.isNotEmpty) {
      final bool matchesTitle = g.title.toLowerCase().contains(searchQuery);
      final bool matchesDesc =
          g.description?.toLowerCase().contains(searchQuery) ?? false;
      final bool matchesCat = g.category.displayName.toLowerCase().contains(
        searchQuery,
      );
      if (!matchesTitle && !matchesDesc && !matchesCat) {
        return false;
      }
    }
    return true;
  }).toList();
});

/// Overall progress summary metrics across active goals
class GoalsOverviewMetrics {
  final int activeCount;
  final int completedCount;
  final int totalCount;
  final double averageProgressPercent;
  final int upcomingDeadlinesCount;

  const GoalsOverviewMetrics({
    required this.activeCount,
    required this.completedCount,
    required this.totalCount,
    required this.averageProgressPercent,
    required this.upcomingDeadlinesCount,
  });
}

final Provider<GoalsOverviewMetrics> goalsOverviewMetricsProvider =
    Provider<GoalsOverviewMetrics>((Ref ref) {
      final AsyncValue<List<Goal>> goalsAsync = ref.watch(
        allGoalsStreamProvider,
      );
      final List<Goal> allGoals = goalsAsync.valueOrNull ?? [];

      final List<Goal> activeGoals = allGoals
          .where((Goal g) => g.status == GoalStatus.active)
          .toList();
      final int completedCount = allGoals
          .where((Goal g) => g.status == GoalStatus.completed)
          .length;

      double totalProgress = 0;
      int upcomingDeadlines = 0;

      for (final Goal g in activeGoals) {
        totalProgress += g.progressPercent;
        if (g.daysRemaining != null &&
            g.daysRemaining! >= 0 &&
            g.daysRemaining! <= 7) {
          upcomingDeadlines++;
        }
      }

      final double avgProgress = activeGoals.isNotEmpty
          ? (totalProgress / activeGoals.length)
          : 0.0;

      return GoalsOverviewMetrics(
        activeCount: activeGoals.length,
        completedCount: completedCount,
        totalCount: allGoals.length,
        averageProgressPercent: avgProgress,
        upcomingDeadlinesCount: upcomingDeadlines,
      );
    });

/// Stream of milestones for a specific goal
final StreamProviderFamily<List<GoalMilestone>, String>
goalMilestonesStreamProvider =
    StreamProvider.family<List<GoalMilestone>, String>((
      Ref ref,
      String goalId,
    ) {
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      return repo.watchMilestones(goalId);
    });

/// Stream of progress updates for a specific goal
final StreamProviderFamily<List<GoalProgressUpdate>, String>
goalProgressUpdatesStreamProvider =
    StreamProvider.family<List<GoalProgressUpdate>, String>((
      Ref ref,
      String goalId,
    ) {
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      return repo.watchProgressUpdates(goalId);
    });

/// Specific goal by ID
final FutureProviderFamily<Goal?, String> goalDetailProvider =
    FutureProvider.family<Goal?, String>((Ref ref, String goalId) async {
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      return repo.getGoalById(goalId);
    });

/// Stream of goals linked to a specific activity
final StreamProviderFamily<List<Goal>, String> goalsForActivityStreamProvider =
    StreamProvider.family<List<Goal>, String>((Ref ref, String activityId) {
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      return repo.watchGoalsForActivity(activityId);
    });
/// Stream of goals linked to a specific activity
final StreamProviderFamily<List<Goal>, String> goalsForActivityStreamProvider =
    StreamProvider.family<List<Goal>, String>((Ref ref, String activityId) {
  final GoalRepository repo = ref.watch(goalRepositoryProvider);
  return repo.watchGoalsForActivity(activityId);
});

/// Weekly insights for goals
class GoalWeeklyInsights {
  final int activeGoalsCount;
  final int completedThisWeekCount;
  final int progressUpdatesCount;
  final List<Goal> approachingDeadlines;

  const GoalWeeklyInsights({
    required this.activeGoalsCount,
    required this.completedThisWeekCount,
    required this.progressUpdatesCount,
    required this.approachingDeadlines,
  });
}

final FutureProviderFamily<GoalWeeklyInsights, DateTime>
goalWeeklyInsightsProvider =
    FutureProvider.family<GoalWeeklyInsights, DateTime>((
      Ref ref,
      DateTime monday,
    ) async {
      final GoalRepository repo = ref.watch(goalRepositoryProvider);
      final DateTime sunday = DateTime(
        monday.year,
        monday.month,
        monday.day + 6,
        23,
        59,
        59,
      );

      final active = await repo.getActiveGoalsCount();
      final completed = await repo.getCompletedGoalsCountForPeriod(
        monday,
        sunday,
      );
      final updatesCount = await repo.getProgressUpdatesCountForPeriod(
        monday,
        sunday,
      );
      final approaching = await repo.getGoalsApproachingDeadline(
        DateTime.now().add(const Duration(days: 7)),
      );

      return GoalWeeklyInsights(
        activeGoalsCount: active,
        completedThisWeekCount: completed,
        progressUpdatesCount: updatesCount,
        approachingDeadlines: approaching,
      );
    });

/// Weekly insights for goals
class GoalWeeklyInsights {
  final int activeGoalsCount;
  final int completedThisWeekCount;
  final int progressUpdatesCount;
  final List<Goal> approachingDeadlines;

  const GoalWeeklyInsights({
    required this.activeGoalsCount,
    required this.completedThisWeekCount,
    required this.progressUpdatesCount,
    required this.approachingDeadlines,
  });
}

final FutureProviderFamily<GoalWeeklyInsights, DateTime>
    goalWeeklyInsightsProvider =
    FutureProvider.family<GoalWeeklyInsights, DateTime>(
        (Ref ref, DateTime monday) async {
  final GoalRepository repo = ref.watch(goalRepositoryProvider);
  final DateTime sunday =
      DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59);

  final active = await repo.getActiveGoalsCount();
  final completed = await repo.getCompletedGoalsCountForPeriod(monday, sunday);
  final updatesCount =
      await repo.getProgressUpdatesCountForPeriod(monday, sunday);
  final approaching = await repo
      .getGoalsApproachingDeadline(DateTime.now().add(const Duration(days: 7)));

  return GoalWeeklyInsights(
    activeGoalsCount: active,
    completedThisWeekCount: completed,
    progressUpdatesCount: updatesCount,
    approachingDeadlines: approaching,
  );
});



