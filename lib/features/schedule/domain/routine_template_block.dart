import 'activity_category.dart';
import 'activity_priority.dart';
import 'time_utils.dart';

class RoutineTemplateBlock implements HasTimeSpan {
  @override
  final String id;
  final String templateId;
  @override
  final String title;
  final ActivityCategory category;
  @override
  final int startMinute;
  @override
  final int endMinute;
  final String? notes;
  final ActivityPriority priority;

  const RoutineTemplateBlock({
    required this.id,
    required this.templateId,
    required this.title,
    required this.category,
    required this.startMinute,
    required this.endMinute,
    this.notes,
    this.priority = ActivityPriority.medium,
  });

  int get durationMinutes => endMinute - startMinute;
  String get durationFormatted => TimeUtils.formatDuration(durationMinutes);
  String get startFormatted => TimeUtils.formatMinutes(startMinute);
  String get endFormatted => TimeUtils.formatMinutes(endMinute);

  RoutineTemplateBlock copyWith({
    String? id,
    String? templateId,
    String? title,
    ActivityCategory? category,
    int? startMinute,
    int? endMinute,
    String? notes,
    ActivityPriority? priority,
  }) {
    return RoutineTemplateBlock(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      category: category ?? this.category,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }
}

