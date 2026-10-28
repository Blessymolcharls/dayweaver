import 'activity_category.dart';
import 'activity_priority.dart';
import 'time_utils.dart';

class Activity implements HasTimeSpan {
  @override
  final String id;
  @override
  final String title;
  final ActivityCategory category;
  final DateTime date;
  @override
  final int startMinute;
  @override
  final int endMinute;
  final String? notes;
  final bool isCompleted;
  final ActivityPriority priority;
  final int? reminderOffsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    this.notes,
    this.isCompleted = false,
    this.priority = ActivityPriority.medium,
    this.reminderOffsetMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get durationMinutes => endMinute - startMinute;

  String get durationFormatted => TimeUtils.formatDuration(durationMinutes);
  String get startFormatted => TimeUtils.formatMinutes(startMinute);
  String get endFormatted => TimeUtils.formatMinutes(endMinute);

  Activity copyWith({
    String? id,
    String? title,
    ActivityCategory? category,
    DateTime? date,
    int? startMinute,
    int? endMinute,
    String? notes,
    bool? isCompleted,
    ActivityPriority? priority,
    int? reminderOffsetMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          date == other.date &&
          startMinute == other.startMinute &&
          endMinute == other.endMinute &&
          notes == other.notes &&
          isCompleted == other.isCompleted &&
          priority == other.priority &&
          reminderOffsetMinutes == other.reminderOffsetMinutes;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      category.hashCode ^
      date.hashCode ^
      startMinute.hashCode ^
      endMinute.hashCode ^
      notes.hashCode ^
      isCompleted.hashCode ^
      priority.hashCode ^
      reminderOffsetMinutes.hashCode;
}
