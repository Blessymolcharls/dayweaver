import 'package:flutter/material.dart';

/// Utilities for working with the 24-hour day represented as 1,440 minutes.
class TimeUtils {
  TimeUtils._();

  static const int minutesPerDay = 1440;

  /// Normalizes a DateTime to calendar date (00:00:00 local time).
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Converts a [TimeOfDay] into total minutes from start of day.
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Converts minute offset (0..1440) to "HH:mm" formatted string.
  /// Note: minute 1440 is represented as "24:00".
  static String formatMinutes(int minutes) {
    final clamped = minutes.clamp(0, minutesPerDay);
    if (clamped == minutesPerDay) {
      return '24:00';
    }
    final hour = clamped ~/ 60;
    final min = clamped % 60;
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  /// Formats duration in minutes to human readable string (e.g., "1h 30m" or "45m").
  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours > 0 && rem > 0) {
      return '${hours}h ${rem}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${rem}m';
    }
  }

  /// Checks if two time spans overlap.
  /// Consecutive activities whose boundaries meet exactly (endA == startB or endB == startA)
  /// are NOT overlapping and are valid.
  static bool doSpansOverlap(int startA, int endA, int startB, int endB) {
    return startA < endB && endA > startB;
  }

  /// Validates an activity's start and end minutes:
  /// - 0 <= start < end <= 1440.
  static String? validateTimeRange(int startMinute, int endMinute) {
    if (startMinute < 0 || startMinute >= minutesPerDay) {
      return 'Start time must be within 00:00 and 23:59';
    }
    if (endMinute <= startMinute) {
      return 'End time must be after start time';
    }
    if (endMinute > minutesPerDay) {
      return 'End time cannot exceed 24:00';
    }
    return null;
  }

  /// Checks whether a candidate range [startMinute, endMinute) overlaps with any existing activities.
  /// [existingActivities] is a list of objects with startMinute, endMinute, and id.
  /// [excludeActivityId] can be supplied when editing an activity to ignore comparing against itself.
  static ({bool hasOverlap, String? conflictingTitle})
  checkOverlap<T extends HasTimeSpan>({
    required int startMinute,
    required int endMinute,
    required List<T> existingActivities,
    String? excludeActivityId,
  }) {
    for (final act in existingActivities) {
      if (excludeActivityId != null && act.id == excludeActivityId) {
        continue;
      }
      if (doSpansOverlap(
        startMinute,
        endMinute,
        act.startMinute,
        act.endMinute,
      )) {
        return (hasOverlap: true, conflictingTitle: act.title);
      }
    }
    return (hasOverlap: false, conflictingTitle: null);
  }

  /// Computes unscheduled free time gaps in a 1,440-minute day.
  /// Assumes [activities] are non-overlapping and sorts them by [startMinute].
  static List<UnscheduledGap> calculateUnscheduledGaps<T extends HasTimeSpan>(
    List<T> activities,
  ) {
    final sorted = List<T>.from(activities)
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    final gaps = <UnscheduledGap>[];
    int currentMinute = 0;

    for (final act in sorted) {
      if (act.startMinute > currentMinute) {
        gaps.add(
          UnscheduledGap(
            startMinute: currentMinute,
            endMinute: act.startMinute,
          ),
        );
      }
      if (act.endMinute > currentMinute) {
        currentMinute = act.endMinute;
      }
    }

    if (currentMinute < minutesPerDay) {
      gaps.add(
        UnscheduledGap(startMinute: currentMinute, endMinute: minutesPerDay),
      );
    }

    return gaps;
  }
}

/// Abstract contract for items occupying time in a schedule.
abstract class HasTimeSpan {
  String get id;
  String get title;
  int get startMinute;
  int get endMinute;
}

/// Represents an empty / unscheduled gap in the timeline.
class UnscheduledGap {
  final int startMinute;
  final int endMinute;

  const UnscheduledGap({required this.startMinute, required this.endMinute});

  int get durationMinutes => endMinute - startMinute;
  String get durationFormatted => TimeUtils.formatDuration(durationMinutes);
  String get startFormatted => TimeUtils.formatMinutes(startMinute);
  String get endFormatted => TimeUtils.formatMinutes(endMinute);
}
