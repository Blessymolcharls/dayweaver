import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/activity_repository.dart';
import '../data/drift_activity_repository.dart';
import '../data/sample_activities.dart';
import '../data/sample_templates.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/routine_template.dart';
import '../domain/time_utils.dart';

/// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Activity repository provider
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftActivityRepository(db);
});

/// Currently selected viewing date for the Today timeline (normalized to midnight)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return TimeUtils.normalizeDate(DateTime.now());
});

/// Currently selected viewing date for the Planner tab (normalized to midnight)
final plannerSelectedDateProvider = StateProvider<DateTime>((ref) {
  return TimeUtils.normalizeDate(DateTime.now());
});

/// Initializes sample data on first run if database is completely empty
final databaseInitializerProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);

  // 1. Seed sample activities for today if no activities exist
  final activityCount = await repo.countActivities();
  if (activityCount == 0) {
    final now = DateTime.now();
    final sample = SampleActivities.generateForDate(now);
    for (final act in sample) {
      await repo.saveActivity(act);
    }
  }

  // 2. Seed default routine templates if no templates exist
  final templateCount = await repo.countTemplates();
  if (templateCount == 0) {
    final defaultTemplates = SampleTemplates.getDefaultTemplates();
    for (final template in defaultTemplates) {
      await repo.saveTemplate(template);
    }
  }
});

/// Stream provider for activities on the currently selected date (Today tab)
final activitiesForSelectedDateProvider = StreamProvider<List<Activity>>((ref) {
  ref.watch(databaseInitializerProvider);
  final repo = ref.watch(activityRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return repo.watchActivitiesForDate(selectedDate);
});

/// Stream provider for activities on the planner selected date (Planner tab)
final activitiesForPlannerDateProvider = StreamProvider<List<Activity>>((ref) {
  ref.watch(databaseInitializerProvider);
  final repo = ref.watch(activityRepositoryProvider);
  final selectedDate = ref.watch(plannerSelectedDateProvider);
  return repo.watchActivitiesForDate(selectedDate);
});

/// Stream provider for all routine templates
final routineTemplatesStreamProvider = StreamProvider<List<RoutineTemplate>>((
  ref,
) {
  ref.watch(databaseInitializerProvider);
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchTemplates();
});

/// Future provider returning the set of dates with activities in a 3-month window around the planner date
final plannerActivityDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  ref.watch(databaseInitializerProvider);
  ref.watch(activitiesForPlannerDateProvider);
  final repo = ref.watch(activityRepositoryProvider);
  final currentDate = ref.watch(plannerSelectedDateProvider);

  final startRange = DateTime(currentDate.year, currentDate.month - 1, 1);
  final endRange = DateTime(currentDate.year, currentDate.month + 2, 0);

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
  final categoryMinutesMap = <ActivityCategory, int>{};

  for (final act in activities) {
    planned += act.durationMinutes;
    categoryMinutesMap[act.category] =
        (categoryMinutesMap[act.category] ?? 0) + act.durationMinutes;

    if (act.isCompleted) {
      completed += act.durationMinutes;
      completedCount++;
    }
  }

  final categoryAllocations = <CategoryAllocation>[];
  if (planned > 0) {
    final sortedEntries = categoryMinutesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
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
final dayMetricsProvider = Provider<DayMetrics>((ref) {
  final activitiesAsync = ref.watch(activitiesForSelectedDateProvider);
  final activities = activitiesAsync.valueOrNull ?? [];
  return calculateDayMetrics(activities);
});

/// Day metrics for the Planner tab
final plannerDayMetricsProvider = Provider<DayMetrics>((ref) {
  final activitiesAsync = ref.watch(activitiesForPlannerDateProvider);
  final activities = activitiesAsync.valueOrNull ?? [];
  return calculateDayMetrics(activities);
});

/// Ticks every 30 seconds to update current time marker for today
final currentMinuteProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>();

  int getCurrentMinute() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  controller.add(getCurrentMinute());

  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
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
