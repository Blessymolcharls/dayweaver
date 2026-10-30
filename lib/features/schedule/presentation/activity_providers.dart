import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_providers.dart';
import '../data/activity_repository.dart';
import '../data/drift_activity_repository.dart';
import '../data/sample_activities.dart';
import '../data/sample_templates.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/daily_review.dart';
import '../domain/recurrence_rule.dart';
import '../domain/routine_template.dart';
import '../domain/time_utils.dart';
import '../domain/weekly_metrics.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/data/sample_goals.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_milestone.dart';
import '../../goals/presentation/goal_providers.dart';

/// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((Ref ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Activity repository provider
final Provider<ActivityRepository> activityRepositoryProvider =
    Provider<ActivityRepository>((Ref ref) {
      final AppDatabase db = ref.watch(appDatabaseProvider);
      final notificationService = ref.watch(notificationServiceProvider);
      return DriftActivityRepository(db, notificationService);
    });

/// Currently selected viewing date for the Today timeline (normalized to midnight)
final StateProvider<DateTime> selectedDateProvider = StateProvider<DateTime>((
  Ref ref,
) {
  return TimeUtils.normalizeDate(DateTime.now());
});

/// Currently selected viewing date for the Planner tab (normalized to midnight)
final StateProvider<DateTime> plannerSelectedDateProvider =
    StateProvider<DateTime>((Ref ref) {
      return TimeUtils.normalizeDate(DateTime.now());
    });

/// Initializes sample data, notification service, and pending reminders on startup
final FutureProvider<void> databaseInitializerProvider = FutureProvider<void>((
  Ref ref,
) async {
  final ActivityRepository repo = ref.watch(activityRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  // 1. Initialize notification system
  await notificationService.initialize();

  // 2. Seed sample activities for today if no activities exist
  final int activityCount = await repo.countActivities();
  if (activityCount == 0) {
    final DateTime now = DateTime.now();
    final List<Activity> sample = SampleActivities.generateForDate(now);
    for (final Activity act in sample) {
      await repo.saveActivity(act);
    }
  }

  // 3. Seed default routine templates if no templates exist
  final int templateCount = await repo.countTemplates();
  if (templateCount == 0) {
    final List<RoutineTemplate> defaultTemplates =
        SampleTemplates.getDefaultTemplates();
    for (final RoutineTemplate template in defaultTemplates) {
      await repo.saveTemplate(template);
    }
  }

  // 4. Seed default recurrence rules if none exist
  final List<RecurrenceRule> existingRules = await repo.getRecurrenceRules();
  if (existingRules.isEmpty) {
    final DateTime today = TimeUtils.normalizeDate(DateTime.now());
    final RecurrenceRule defaultRecurrence = RecurrenceRule(
      id: 'default_rule_coding',
      title: 'Daily Coding Practice',
      category: ActivityCategory.coding,
      startMinute: 17 * 60, // 17:00
      endMinute: 18 * 60 + 30, // 18:30
      recurrenceType: RecurrenceType.weekdays,
      daysOfWeek: [1, 2, 3, 4, 5],
      startDate: today,
      notes: 'Consistent daily problem solving & personal project building.',
    );
    await repo.saveRecurrenceRule(defaultRecurrence);
  }

  // 5. Generate recurring activities for today
  final DateTime today = TimeUtils.normalizeDate(DateTime.now());
  await repo.generateRecurringActivitiesForDate(today);

  // 6. Rebuild pending reminders from today forward
  final DateTime futureLimit = today.add(const Duration(days: 14));
  final List<Activity> upcoming = await repo.getActivitiesForDateRange(
    today,
    futureLimit,
  );
  final List<Activity> needReminder = upcoming
      .where((Activity a) => a.reminderOffsetMinutes != null && !a.isCompleted)
      .toList();
  await notificationService.rescheduleAllReminders(needReminder);

  // 7. Seed default goals if no goals exist
  final GoalRepository goalRepo = ref.watch(goalRepositoryProvider);
  final List<Goal> existingGoals = await goalRepo.getGoals();
  if (existingGoals.isEmpty) {
    for (final Goal g in SampleGoals.getDefaultGoals()) {
      await goalRepo.saveGoal(g);
      for (final GoalMilestone m in g.milestones) {
        await goalRepo.saveMilestone(m);
      }
    }
  }
});

/// Stream provider for activities on the currently selected date (Today tab)
final StreamProvider<List<Activity>> activitiesForSelectedDateProvider =
    StreamProvider<List<Activity>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      final DateTime selectedDate = ref.watch(selectedDateProvider);

      // Idempotently ensure recurring activities exist for this date
      repo.generateRecurringActivitiesForDate(selectedDate);

      return repo.watchActivitiesForDate(selectedDate);
    });

/// Stream provider for activities on the planner selected date (Planner tab)
final StreamProvider<List<Activity>> activitiesForPlannerDateProvider =
    StreamProvider<List<Activity>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      final DateTime selectedDate = ref.watch(plannerSelectedDateProvider);

      // Idempotently ensure recurring activities exist for this date
      repo.generateRecurringActivitiesForDate(selectedDate);

      return repo.watchActivitiesForDate(selectedDate);
    });

/// Stream provider for all routine templates
final StreamProvider<List<RoutineTemplate>> routineTemplatesStreamProvider =
    StreamProvider<List<RoutineTemplate>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      return repo.watchTemplates();
    });

/// Stream provider for all recurrence rules
final StreamProvider<List<RecurrenceRule>> recurrenceRulesStreamProvider =
    StreamProvider<List<RecurrenceRule>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      return repo.watchRecurrenceRules();
    });

/// Future provider returning the set of dates with activities in a 3-month window around the planner date
final FutureProvider<Set<DateTime>> plannerActivityDatesProvider =
    FutureProvider<Set<DateTime>>((Ref ref) async {
      ref.watch(databaseInitializerProvider);
      ref.watch(activitiesForPlannerDateProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      final DateTime currentDate = ref.watch(plannerSelectedDateProvider);

      final DateTime startRange = DateTime(
        currentDate.year,
        currentDate.month - 1,
        1,
      );
      final DateTime endRange = DateTime(
        currentDate.year,
        currentDate.month + 2,
        0,
      );

      return repo.getDatesWithActivities(startRange, endRange);
    });

/// Category allocation breakdown item
class CategoryAllocation {
  final ActivityCategory category;
  final int minutes;
  final double percentageOfPlanned;

  const CategoryAllocation({
    required this.category,
    required this.minutes,
    required this.percentageOfPlanned,
  });

  String get durationFormatted => TimeUtils.formatDuration(minutes);
  int get percentageRound => (percentageOfPlanned * 100).round();
}

/// Rich duration-based Day Accounting metrics
class DayMetrics {
  final int totalPlannedMinutes;
  final int completedMinutes;
  final int totalActivities;
  final int completedActivities;
  final List<CategoryAllocation> categoryAllocations;

  const DayMetrics({
    required this.totalPlannedMinutes,
    required this.completedMinutes,
    required this.totalActivities,
    required this.completedActivities,
    this.categoryAllocations = const [],
  });

  /// Duration-based completion ratio (0.0 to 1.0)
  double get completionRatio => totalPlannedMinutes == 0
      ? 0.0
      : (completedMinutes / totalPlannedMinutes).clamp(0.0, 1.0);

  /// Duration-based completion percentage
  int get completionPercent => (completionRatio * 100).round();

  /// Remaining planned duration in minutes
  int get remainingMinutes => (totalPlannedMinutes - completedMinutes).clamp(
    0,
    TimeUtils.minutesPerDay,
  );

  /// Remaining unfinished tasks count
  int get remainingActivities =>
      (totalActivities - completedActivities).clamp(0, totalActivities);

  /// Unscheduled available free minutes in the 1440-minute day
  int get freeMinutes => (TimeUtils.minutesPerDay - totalPlannedMinutes).clamp(
    0,
    TimeUtils.minutesPerDay,
  );

  String get plannedDurationFormatted =>
      TimeUtils.formatDuration(totalPlannedMinutes);

  String get completedDurationFormatted =>
      TimeUtils.formatDuration(completedMinutes);

  String get remainingDurationFormatted =>
      TimeUtils.formatDuration(remainingMinutes);

  String get freeDurationFormatted => TimeUtils.formatDuration(freeMinutes);
}

/// Computes metrics from an activity list
DayMetrics calculateDayMetrics(List<Activity> activities) {
  int planned = 0;
  int completed = 0;
  int completedCount = 0;
  final Map<ActivityCategory, int> categoryMinutesMap =
      <ActivityCategory, int>{};

  for (final Activity act in activities) {
    planned += act.durationMinutes;
    categoryMinutesMap[act.category] =
        (categoryMinutesMap[act.category] ?? 0) + act.durationMinutes;

    if (act.isCompleted) {
      completed += act.durationMinutes;
      completedCount++;
    }
  }

  final List<CategoryAllocation> categoryAllocations = <CategoryAllocation>[];
  if (planned > 0) {
    final List<MapEntry<ActivityCategory, int>> sortedEntries =
        categoryMinutesMap.entries.toList()..sort(
          (
            MapEntry<ActivityCategory, int> a,
            MapEntry<ActivityCategory, int> b,
          ) => b.value.compareTo(a.value),
        );

    for (final MapEntry<ActivityCategory, int> entry in sortedEntries) {
      categoryAllocations.add(
        CategoryAllocation(
          category: entry.key,
          minutes: entry.value,
          percentageOfPlanned: entry.value / planned,
        ),
      );
    }
  }

  return DayMetrics(
    totalPlannedMinutes: planned,
    completedMinutes: completed,
    totalActivities: activities.length,
    completedActivities: completedCount,
    categoryAllocations: categoryAllocations,
  );
}

/// Day metrics for the Today tab
final Provider<DayMetrics> dayMetricsProvider = Provider<DayMetrics>((Ref ref) {
  final AsyncValue<List<Activity>> activitiesAsync = ref.watch(
    activitiesForSelectedDateProvider,
  );
  final List<Activity> activities = activitiesAsync.valueOrNull ?? [];
  return calculateDayMetrics(activities);
});

/// Day metrics for the Planner tab
final Provider<DayMetrics> plannerDayMetricsProvider = Provider<DayMetrics>((
  Ref ref,
) {
  final AsyncValue<List<Activity>> activitiesAsync = ref.watch(
    activitiesForPlannerDateProvider,
  );
  final List<Activity> activities = activitiesAsync.valueOrNull ?? [];
  return calculateDayMetrics(activities);
});

/// Ticks every 30 seconds to update current time marker for today
final StreamProvider<int> currentMinuteProvider = StreamProvider<int>((
  Ref ref,
) {
  final StreamController<int> controller = StreamController<int>();

  int getCurrentMinute() {
    final DateTime now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  controller.add(getCurrentMinute());

  final Timer timer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (!controller.isClosed) {
      controller.add(getCurrentMinute());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// ==================== Weekly Insights Providers ====================

/// Currently selected week's Monday (normalized)
final StateProvider<DateTime> selectedWeekStartProvider =
    StateProvider<DateTime>((Ref ref) {
      final DateTime now = TimeUtils.normalizeDate(DateTime.now());
      return DateTime(now.year, now.month, now.day - (now.weekday - 1));
    });

/// Stream of activities for the selected week
final StreamProvider<List<Activity>> weeklyActivitiesProvider =
    StreamProvider<List<Activity>>((Ref ref) {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      final DateTime monday = ref.watch(selectedWeekStartProvider);
      final DateTime sunday = DateTime(
        monday.year,
        monday.month,
        monday.day + 6,
      );
      return repo.watchActivitiesForDateRange(monday, sunday);
    });

/// WeeklyMetrics calculated from the selected week's activities
final Provider<WeeklyMetrics> weeklyMetricsProvider = Provider<WeeklyMetrics>((
  Ref ref,
) {
  final DateTime monday = ref.watch(selectedWeekStartProvider);
  final DateTime sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final AsyncValue<List<Activity>> activitiesAsync = ref.watch(
    weeklyActivitiesProvider,
  );
  final List<Activity> activities = activitiesAsync.valueOrNull ?? [];

  return WeeklyMetrics.fromActivities(
    startOfWeek: monday,
    endOfWeek: sunday,
    activities: activities,
  );
});

// ==================== Daily Review Providers ====================

/// Selected date to review
final StateProvider<DateTime> dailyReviewDateProvider = StateProvider<DateTime>(
  (Ref ref) {
    return TimeUtils.normalizeDate(DateTime.now());
  },
);

/// Daily review record for the selected review date
final FutureProvider<DailyReview?> dailyReviewProvider =
    FutureProvider<DailyReview?>((Ref ref) async {
      ref.watch(databaseInitializerProvider);
      final ActivityRepository repo = ref.watch(activityRepositoryProvider);
      final DateTime reviewDate = ref.watch(dailyReviewDateProvider);
      return repo.getDailyReview(reviewDate);
    });
