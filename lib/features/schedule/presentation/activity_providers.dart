import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/activity_repository.dart';
import '../data/drift_activity_repository.dart';
import '../data/sample_activities.dart';
import '../domain/activity.dart';
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

/// Currently selected viewing date (normalized to midnight)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return TimeUtils.normalizeDate(DateTime.now());
});

/// Initializes sample data on first run if database is completely empty
final databaseInitializerProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  final count = await repo.countActivities();
  if (count == 0) {
    final now = DateTime.now();
    final sample = SampleActivities.generateForDate(now);
    for (final act in sample) {
      await repo.saveActivity(act);
    }
  }
});

/// Stream provider for activities on the currently selected date
final activitiesForSelectedDateProvider = StreamProvider<List<Activity>>((ref) {
  // Ensure database initialization has executed
  ref.watch(databaseInitializerProvider);
  final repo = ref.watch(activityRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return repo.watchActivitiesForDate(selectedDate);
});

/// Summary statistics for the current selected day
class DayMetrics {
  final int totalPlannedMinutes;
  final int completedMinutes;
  final int totalActivities;
  final int completedActivities;

  const DayMetrics({
    required this.totalPlannedMinutes,
    required this.completedMinutes,
    required this.totalActivities,
    required this.completedActivities,
  });

  double get completionRatio =>
      totalActivities == 0 ? 0.0 : completedActivities / totalActivities;

  int get completionPercent => (completionRatio * 100).round();

  String get plannedDurationFormatted =>
      TimeUtils.formatDuration(totalPlannedMinutes);

  String get completedDurationFormatted =>
      TimeUtils.formatDuration(completedMinutes);
}

final dayMetricsProvider = Provider<DayMetrics>((ref) {
  final activitiesAsync = ref.watch(activitiesForSelectedDateProvider);
  final activities = activitiesAsync.valueOrNull ?? [];

  int planned = 0;
  int completed = 0;
  int completedCount = 0;

  for (final act in activities) {
    planned += act.durationMinutes;
    if (act.isCompleted) {
      completed += act.durationMinutes;
      completedCount++;
    }
  }

  return DayMetrics(
    totalPlannedMinutes: planned,
    completedMinutes: completed,
    totalActivities: activities.length,
    completedActivities: completedCount,
  );
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
