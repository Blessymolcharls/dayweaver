import 'package:flutter/foundation.dart';

@immutable
class GoalMilestone {
  final String id;
  final String goalId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final int orderIndex;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.description,
    this.targetDate,
    this.orderIndex = 0,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  GoalMilestone copyWith({
    String? id,
    String? goalId,
    String? title,
    String? description,
    DateTime? targetDate,
    int? orderIndex,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      orderIndex: orderIndex ?? this.orderIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalMilestone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          title == other.title &&
          description == other.description &&
          targetDate == other.targetDate &&
          orderIndex == other.orderIndex &&
          isCompleted == other.isCompleted &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      targetDate.hashCode ^
      orderIndex.hashCode ^
      isCompleted.hashCode ^
      completedAt.hashCode;
}
