import 'activity_category.dart';
import 'activity_priority.dart';
import 'time_utils.dart';

enum RecurrenceType {
  daily,
  weekdays,
  custom;

  static RecurrenceType fromString(String val) {
    switch (val) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekdays':
        return RecurrenceType.weekdays;
      default:
        return RecurrenceType.custom;
    }
  }
}

class RecurrenceRule implements HasTimeSpan {
  @override
  final String id;
  @override
  final String title;
  final ActivityCategory category;
  @override
  final int startMinute;
  @override
  final int endMinute;
  final RecurrenceType recurrenceType;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final ActivityPriority priority;
  final int? reminderOffsetMinutes;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurrenceRule({
    required this.id,
    required this.title,
    required this.category,
    required this.startMinute,
    required this.endMinute,
    required this.recurrenceType,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.notes,
    this.priority = ActivityPriority.medium,
    this.reminderOffsetMinutes,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get durationMinutes => endMinute - startMinute;
  String get durationFormatted => TimeUtils.formatDuration(durationMinutes);
  String get startFormatted => TimeUtils.formatMinutes(startMinute);
  String get endFormatted => TimeUtils.formatMinutes(endMinute);

  /// Checks if this rule applies to a specific calendar [date].
  bool matchesDate(DateTime date) {
    if (!isEnabled) return false;

    final DateTime normalized = TimeUtils.normalizeDate(date);
    final DateTime normStart = TimeUtils.normalizeDate(startDate);
    if (normalized.isBefore(normStart)) return false;

    if (endDate != null) {
      final DateTime normEnd = TimeUtils.normalizeDate(endDate!);
      if (normalized.isAfter(normEnd)) return false;
    }

    switch (recurrenceType) {
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.weekdays:
        return normalized.weekday >= 1 && normalized.weekday <= 5;
      case RecurrenceType.custom:
        return daysOfWeek.contains(normalized.weekday);
    }
  }

  String get recurrenceDescription {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return 'Every day';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon - Fri)';
      case RecurrenceType.custom:
        const Map<int, String> names = {
          1: 'Mon',
          2: 'Tue',
          3: 'Wed',
          4: 'Thu',
          5: 'Fri',
          6: 'Sat',
          7: 'Sun',
        };
        final List<String> selectedNames = daysOfWeek
            .map((int d) => names[d] ?? '')
            .where((String s) => s.isNotEmpty)
            .toList();
        return selectedNames.isEmpty
            ? 'No days selected'
            : selectedNames.join(', ');
    }
  }

  RecurrenceRule copyWith({
    String? id,
    String? title,
    ActivityCategory? category,
    int? startMinute,
    int? endMinute,
    RecurrenceType? recurrenceType,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    ActivityPriority? priority,
    int? reminderOffsetMinutes,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
