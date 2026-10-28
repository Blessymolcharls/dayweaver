import 'activity.dart';
import 'activity_category.dart';
import 'time_utils.dart';

class DailyOverviewData {
  final DateTime date;
  final int plannedMinutes;
  final int completedMinutes;
  final int completedCount;
  final int unfinishedCount;

  DailyOverviewData({
    required this.date,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.completedCount,
    required this.unfinishedCount,
  });

  double get completionRatio =>
      plannedMinutes > 0 ? completedMinutes / plannedMinutes : 0.0;
  int get completionPercent => (completionRatio * 100).round();
}

class WeeklyMetrics {
  final DateTime startOfWeek;
  final DateTime endOfWeek;
  final int totalPlannedMinutes;
  final int totalCompletedMinutes;
  final int completedActivitiesCount;
  final int unfinishedActivitiesCount;
  final Map<ActivityCategory, int> categoryMinutes;
  final Map<ActivityCategory, int> categoryPercentages;
  final List<DailyOverviewData> dailyBreakdowns;

  WeeklyMetrics({
    required this.startOfWeek,
    required this.endOfWeek,
    required this.totalPlannedMinutes,
    required this.totalCompletedMinutes,
    required this.completedActivitiesCount,
    required this.unfinishedActivitiesCount,
    required this.categoryMinutes,
    required this.categoryPercentages,
    required this.dailyBreakdowns,
  });

  double get completionRatio => totalPlannedMinutes > 0
      ? totalCompletedMinutes / totalPlannedMinutes
      : 0.0;
  int get completionPercent => (completionRatio * 100).round();

  int get totalFreeMinutes =>
      ((7 * 1440) - totalPlannedMinutes).clamp(0, 7 * 1440);

  String get totalPlannedFormatted =>
      TimeUtils.formatDuration(totalPlannedMinutes);
  String get totalCompletedFormatted =>
      TimeUtils.formatDuration(totalCompletedMinutes);
  String get totalFreeFormatted => TimeUtils.formatDuration(totalFreeMinutes);

  factory WeeklyMetrics.fromActivities({
    required DateTime startOfWeek,
    required DateTime endOfWeek,
    required List<Activity> activities,
  }) {
    int totalPlanned = 0;
    int totalCompleted = 0;
    int completedCount = 0;
    int unfinishedCount = 0;
    final Map<ActivityCategory, int> catMinutes = {};

    for (final Activity a in activities) {
      totalPlanned += a.durationMinutes;
      if (a.isCompleted) {
        totalCompleted += a.durationMinutes;
        completedCount++;
      } else {
        unfinishedCount++;
      }
      catMinutes[a.category] =
          (catMinutes[a.category] ?? 0) + a.durationMinutes;
    }

    final Map<ActivityCategory, int> catPct = {};
    if (totalPlanned > 0) {
      for (final MapEntry<ActivityCategory, int> entry in catMinutes.entries) {
        catPct[entry.key] = ((entry.value / totalPlanned) * 100).round();
      }
    }

    // Build 7-day breakdown
    final List<DailyOverviewData> days = [];
    DateTime cursor = startOfWeek;
    for (int i = 0; i < 7; i++) {
      final DateTime day = DateTime(cursor.year, cursor.month, cursor.day + i);
      final List<Activity> dayActs = activities
          .where(
            (Activity a) =>
                a.date.year == day.year &&
                a.date.month == day.month &&
                a.date.day == day.day,
          )
          .toList();

      int dPlanned = 0;
      int dCompleted = 0;
      int dCompCount = 0;
      int dUnfinCount = 0;

      for (final Activity a in dayActs) {
        dPlanned += a.durationMinutes;
        if (a.isCompleted) {
          dCompleted += a.durationMinutes;
          dCompCount++;
        } else {
          dUnfinCount++;
        }
      }

      days.add(
        DailyOverviewData(
          date: day,
          plannedMinutes: dPlanned,
          completedMinutes: dCompleted,
          completedCount: dCompCount,
          unfinishedCount: dUnfinCount,
        ),
      );
    }

    return WeeklyMetrics(
      startOfWeek: startOfWeek,
      endOfWeek: endOfWeek,
      totalPlannedMinutes: totalPlanned,
      totalCompletedMinutes: totalCompleted,
      completedActivitiesCount: completedCount,
      unfinishedActivitiesCount: unfinishedCount,
      categoryMinutes: catMinutes,
      categoryPercentages: catPct,
      dailyBreakdowns: days,
    );
  }
}
