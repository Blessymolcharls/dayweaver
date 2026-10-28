import 'package:flutter_test/flutter_test.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/activity_priority.dart';

void main() {
  group('Activity Domain Model', () {
    test('calculates duration and formatted strings correctly', () {
      final act = Activity(
        id: 'act-1',
        title: 'Algorithms Exam',
        category: ActivityCategory.college,
        date: DateTime(2026, 10, 24),
        startMinute: 600, // 10:00
        endMinute: 750, // 12:30
      );

      expect(act.durationMinutes, 150);
      expect(act.durationFormatted, '2h 30m');
      expect(act.startFormatted, '10:00');
      expect(act.endFormatted, '12:30');
      expect(act.isCompleted, isFalse);
    });

    test('copyWith preserves properties and updates specified ones', () {
      final act = Activity(
        id: 'act-1',
        title: 'Original Title',
        category: ActivityCategory.coding,
        date: DateTime(2026, 10, 24),
        startMinute: 300,
        endMinute: 360,
        isCompleted: false,
        priority: ActivityPriority.low,
      );

      final updated = act.copyWith(
        title: 'Updated Title',
        isCompleted: true,
        priority: ActivityPriority.high,
      );

      expect(updated.id, 'act-1');
      expect(updated.title, 'Updated Title');
      expect(updated.category, ActivityCategory.coding);
      expect(updated.isCompleted, isTrue);
      expect(updated.priority, ActivityPriority.high);
    });
  });

  group('Enums parsing', () {
    test('ActivityCategory fromString matches or defaults safely', () {
      expect(ActivityCategory.fromString('college'), ActivityCategory.college);
      expect(ActivityCategory.fromString('coding'), ActivityCategory.coding);
      expect(ActivityCategory.fromString('meals'), ActivityCategory.meals);
      expect(ActivityCategory.fromString('sleep'), ActivityCategory.sleep);
      expect(
        ActivityCategory.fromString('unknown_value'),
        ActivityCategory.personal,
      );
    });

    test('ActivityPriority fromString matches or defaults safely', () {
      expect(ActivityPriority.fromString('low'), ActivityPriority.low);
      expect(ActivityPriority.fromString('medium'), ActivityPriority.medium);
      expect(ActivityPriority.fromString('high'), ActivityPriority.high);
      expect(ActivityPriority.fromString('invalid'), ActivityPriority.medium);
    });
  });
}
