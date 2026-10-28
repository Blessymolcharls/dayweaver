import 'time_utils.dart';

class DailyReview {
  final DateTime date; // normalized
  final String? reflectionNotes;
  final int completedTasksCount;
  final int totalTasksCount;
  final int completedMinutes;
  final int totalPlannedMinutes;
  final DateTime reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyReview({
    required this.date,
    this.reflectionNotes,
    this.completedTasksCount = 0,
    this.totalTasksCount = 0,
    this.completedMinutes = 0,
    this.totalPlannedMinutes = 0,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get remainingMinutes =>
      (totalPlannedMinutes - completedMinutes).clamp(0, 1440);
  int get freeMinutes => (1440 - totalPlannedMinutes).clamp(0, 1440);

  double get completionRatio =>
      totalPlannedMinutes > 0 ? completedMinutes / totalPlannedMinutes : 0.0;
  int get completionPercent => (completionRatio * 100).round();

  String get completedDurationFormatted =>
      TimeUtils.formatDuration(completedMinutes);
  String get totalPlannedDurationFormatted =>
      TimeUtils.formatDuration(totalPlannedMinutes);

  DailyReview copyWith({
    DateTime? date,
    String? reflectionNotes,
    int? completedTasksCount,
    int? totalTasksCount,
    int? completedMinutes,
    int? totalPlannedMinutes,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReview(
      date: date ?? this.date,
      reflectionNotes: reflectionNotes ?? this.reflectionNotes,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      totalTasksCount: totalTasksCount ?? this.totalTasksCount,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      totalPlannedMinutes: totalPlannedMinutes ?? this.totalPlannedMinutes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
