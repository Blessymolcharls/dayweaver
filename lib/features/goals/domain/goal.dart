import 'package:flutter/foundation.dart';
import '../../schedule/domain/activity_priority.dart';
import '../../schedule/domain/time_utils.dart';
import 'goal_category.dart';
import 'goal_milestone.dart';
import 'goal_status.dart';

@immutable
class Goal {
  final String id;
  final String title;
  final String? description;
  final GoalCategory category;
  final GoalStatus status;
  final ActivityPriority priority;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime startDate;
  final DateTime? targetDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoalMilestone> milestones;
  final List<String> linkedActivityIds;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.status = GoalStatus.active,
    this.priority = ActivityPriority.medium,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
    required this.startDate,
    this.targetDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.milestones = const [],
    this.linkedActivityIds = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get progressRatio =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  int get progressPercent => (progressRatio * 100).round();

  double get remainingValue =>
      (targetValue - currentValue).clamp(0.0, double.infinity);

  bool get isTargetReached => currentValue >= targetValue;

  int get milestonesCompletedCount =>
      milestones.where((GoalMilestone m) => m.isCompleted).length;

  int get milestonesTotalCount => milestones.length;

  double get milestoneProgressRatio => milestones.isNotEmpty
      ? milestonesCompletedCount / milestones.length
      : 0.0;

  int get milestoneProgressPercent => (milestoneProgressRatio * 100).round();

  bool get isCompleted => status == GoalStatus.completed;
  bool get isArchived => status == GoalStatus.archived;
  bool get isActive => status == GoalStatus.active;
  bool get isPaused => status == GoalStatus.paused;

  bool get isPastDeadline {
    if (targetDate == null || status.isCompleted) return false;
    final DateTime now = TimeUtils.normalizeDate(DateTime.now());
    final DateTime deadline = TimeUtils.normalizeDate(targetDate!);
    return now.isAfter(deadline);
  }

  int? get daysRemaining {
    if (targetDate == null) return null;
    final DateTime now = TimeUtils.normalizeDate(DateTime.now());
    final DateTime deadline = TimeUtils.normalizeDate(targetDate!);
    return deadline.difference(now).inDays;
  }

  String get formattedCurrent => '${_formatNumber(currentValue)} $unit';
  String get formattedTarget => '${_formatNumber(targetValue)} $unit';

  bool isApproachingDeadline({int withinDays = 7}) {
    if (targetDate == null || status.isCompleted) return false;
    final int? remaining = daysRemaining;
    return remaining != null && remaining >= 0 && remaining <= withinDays;
  }

  String get formattedProgress =>
      '${_formatNumber(currentValue)} / ${_formatNumber(targetValue)} $unit';

  String get formattedRemaining =>
      '${_formatNumber(remainingValue)} $unit remaining';

  static String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    GoalStatus? status,
    ActivityPriority? priority,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? startDate,
    DateTime? targetDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GoalMilestone>? milestones,
    List<String>? linkedActivityIds,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      milestones: milestones ?? this.milestones,
      linkedActivityIds: linkedActivityIds ?? this.linkedActivityIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          status == other.status &&
          priority == other.priority &&
          targetValue == other.targetValue &&
          currentValue == other.currentValue &&
          unit == other.unit &&
          startDate == other.startDate &&
          targetDate == other.targetDate;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      category.hashCode ^
      status.hashCode ^
      priority.hashCode ^
      targetValue.hashCode ^
      currentValue.hashCode ^
      unit.hashCode ^
      startDate.hashCode ^
      targetDate.hashCode;
}
