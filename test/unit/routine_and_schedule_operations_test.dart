import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayweaver/core/database/app_database.dart';
import 'package:dayweaver/features/schedule/data/drift_activity_repository.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/activity_priority.dart';
import 'package:dayweaver/features/schedule/domain/conflict_strategy.dart';
import 'package:dayweaver/features/schedule/domain/routine_template.dart';
import 'package:dayweaver/features/schedule/domain/routine_template_block.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

void main() {
  late AppDatabase db;
  late DriftActivityRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftActivityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Routine Templates CRUD & Metrics', () {
    test(
      'creates, retrieves, and updates routine templates with blocks',
      () async {
        final template = RoutineTemplate(
          id: 'tmpl-1',
          name: 'Study Marathon',
          description: 'Focus blocks with intentional rest.',
          blocks: [
            const RoutineTemplateBlock(
              id: 'b-1',
              templateId: 'tmpl-1',
              title: 'Deep Math Study',
              category: ActivityCategory.college,
              startMinute: 540, // 09:00
              endMinute: 720, // 12:00
              priority: ActivityPriority.high,
            ),
            const RoutineTemplateBlock(
              id: 'b-2',
              templateId: 'tmpl-1',
              title: 'Lunch & Walk',
              category: ActivityCategory.meals,
              startMinute: 720, // 12:00
              endMinute: 780, // 13:00
              priority: ActivityPriority.low,
            ),
          ],
        );

        await repo.saveTemplate(template);

        final retrieved = await repo.getTemplateById('tmpl-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.name, 'Study Marathon');
        expect(retrieved.blockCount, 2);
        expect(retrieved.totalPlannedMinutes, 240); // 180 + 60
        expect(retrieved.totalDurationFormatted, '4h');

        // Update template with an additional block
        final block3 = const RoutineTemplateBlock(
          id: 'b-3',
          templateId: 'tmpl-1',
          title: 'Review & Homework',
          category: ActivityCategory.personal,
          startMinute: 840,
          endMinute: 960,
        );
        await repo.saveTemplateBlock(block3);

        final updated = await repo.getTemplateById('tmpl-1');
        expect(updated!.blockCount, 3);
        expect(updated.totalPlannedMinutes, 360); // 6h

        // Delete block
        await repo.deleteTemplateBlock('b-3');
        final afterDelete = await repo.getTemplateById('tmpl-1');
        expect(afterDelete!.blockCount, 2);

        // Delete template
        await repo.deleteTemplate('tmpl-1');
        final nonExistent = await repo.getTemplateById('tmpl-1');
        expect(nonExistent, isNull);
      },
    );
  });

  group('Applying Routine Templates to Dates', () {
    final testDate = DateTime(2026, 10, 28);

    setUp(() async {
      final template = RoutineTemplate(
        id: 'tmpl-routine',
        name: 'Coding Day',
        blocks: [
          const RoutineTemplateBlock(
            id: 'tb-1',
            templateId: 'tmpl-routine',
            title: 'Morning Architecture',
            category: ActivityCategory.coding,
            startMinute: 540, // 09:00
            endMinute: 660, // 11:00
          ),
          const RoutineTemplateBlock(
            id: 'tb-2',
            templateId: 'tmpl-routine',
            title: 'Lunch',
            category: ActivityCategory.meals,
            startMinute: 720, // 12:00
            endMinute: 780, // 13:00
          ),
          const RoutineTemplateBlock(
            id: 'tb-3',
            templateId: 'tmpl-routine',
            title: 'Flutter Feature Build',
            category: ActivityCategory.coding,
            startMinute: 840, // 14:00
            endMinute: 1020, // 17:00
          ),
        ],
      );
      await repo.saveTemplate(template);
    });

    test('applies template to an empty date successfully', () async {
      final res = await repo.applyTemplateToDate(
        templateId: 'tmpl-routine',
        date: testDate,
        conflictStrategy: ConflictStrategy.abortOnConflict,
      );

      expect(res.success, isTrue);
      expect(res.addedCount, 3);
      expect(res.skippedCount, 0);

      final activities = await repo.getActivitiesForDate(testDate);
      expect(activities.length, 3);
      expect(activities[0].title, 'Morning Architecture');
      expect(activities[0].date, testDate);
      expect(activities[0].isCompleted, isFalse);
    });

    test(
      'partially occupied date with ConflictStrategy.skipConflicts inserts non-overlapping blocks',
      () async {
        // Existing activity from 10:00 to 12:30 (conflicts with 09:00 - 11:00 and 12:00 - 13:00)
        await repo.saveActivity(
          Activity(
            id: 'existing-1',
            title: 'Existing Midday Lecture',
            category: ActivityCategory.college,
            date: testDate,
            startMinute: 600, // 10:00
            endMinute: 750, // 12:30
          ),
        );

        final res = await repo.applyTemplateToDate(
          templateId: 'tmpl-routine',
          date: testDate,
          conflictStrategy: ConflictStrategy.skipConflicts,
        );

        expect(res.success, isTrue);
        expect(res.addedCount, 1); // tb-3 (14:00 - 17:00) does not conflict
        expect(res.skippedCount, 2); // tb-1 and tb-2 conflict and were skipped

        final all = await repo.getActivitiesForDate(testDate);
        expect(all.length, 2); // existing + 1 added
        expect(all.any((a) => a.title == 'Flutter Feature Build'), isTrue);
        expect(all.any((a) => a.title == 'Existing Midday Lecture'), isTrue);
      },
    );

    test(
      'ConflictStrategy.overwrite clears existing and applies all blocks',
      () async {
        await repo.saveActivity(
          Activity(
            id: 'old-1',
            title: 'Stale Activity',
            category: ActivityCategory.personal,
            date: testDate,
            startMinute: 100,
            endMinute: 200,
          ),
        );

        final res = await repo.applyTemplateToDate(
          templateId: 'tmpl-routine',
          date: testDate,
          conflictStrategy: ConflictStrategy.overwrite,
        );

        expect(res.success, isTrue);
        expect(res.addedCount, 3);

        final all = await repo.getActivitiesForDate(testDate);
        expect(all.length, 3);
        expect(all.any((a) => a.title == 'Stale Activity'), isFalse);
      },
    );

    test(
      'ConflictStrategy.abortOnConflict rolls back transaction without mutating database',
      () async {
        await repo.saveActivity(
          Activity(
            id: 'existing-clash',
            title: 'Clashing Appointment',
            category: ActivityCategory.personal,
            date: testDate,
            startMinute: 600,
            endMinute: 700,
          ),
        );

        final res = await repo.applyTemplateToDate(
          templateId: 'tmpl-routine',
          date: testDate,
          conflictStrategy: ConflictStrategy.abortOnConflict,
        );

        expect(res.success, isFalse);
        expect(
          res.errorMessage,
          contains('conflicts with "Clashing Appointment"'),
        );

        // Verify transaction rollback: only the original activity remains
        final all = await repo.getActivitiesForDate(testDate);
        expect(all.length, 1);
        expect(all.first.id, 'existing-clash');
      },
    );
  });

  group('Schedule Copying & Transactions', () {
    final fromDate = DateTime(2026, 10, 28);
    final toDate = DateTime(2026, 10, 29);

    setUp(() async {
      await repo.saveActivity(
        Activity(
          id: 'act-1',
          title: 'Algorithms Lecture',
          category: ActivityCategory.college,
          date: fromDate,
          startMinute: 540,
          endMinute: 660,
          isCompleted: true,
        ),
      );
      await repo.saveActivity(
        Activity(
          id: 'act-2',
          title: 'DSA Practice',
          category: ActivityCategory.coding,
          date: fromDate,
          startMinute: 720,
          endMinute: 840,
        ),
      );
    });

    test(
      'copies schedule from source date to destination date with uncompleted status',
      () async {
        final res = await repo.copySchedule(
          fromDate: fromDate,
          toDate: toDate,
          conflictStrategy: ConflictStrategy.abortOnConflict,
        );

        expect(res.success, isTrue);
        expect(res.addedCount, 2);

        final destActivities = await repo.getActivitiesForDate(toDate);
        expect(destActivities.length, 2);
        expect(destActivities[0].title, 'Algorithms Lecture');
        expect(destActivities[0].date, toDate);
        expect(destActivities[0].isCompleted, isFalse); // Reset to incomplete
        expect(destActivities[0].id, isNot('act-1')); // New ID
      },
    );

    test(
      'rejects copying when source and destination are the same date',
      () async {
        final res = await repo.copySchedule(
          fromDate: fromDate,
          toDate: fromDate,
          conflictStrategy: ConflictStrategy.skipConflicts,
        );

        expect(res.success, isFalse);
        expect(res.errorMessage, contains('cannot be the same'));
      },
    );
  });

  group('Activity Duplication and Moving', () {
    final date = DateTime(2026, 10, 28);

    test('duplicateActivity creates independent copy with new ID', () async {
      await repo.saveActivity(
        Activity(
          id: 'orig-1',
          title: 'Chemistry Lab',
          category: ActivityCategory.college,
          date: date,
          startMinute: 500,
          endMinute: 600,
          isCompleted: true,
        ),
      );

      final dup = await repo.duplicateActivity('orig-1');
      expect(dup.id, isNot('orig-1'));
      expect(dup.title, 'Chemistry Lab (Copy)');
      expect(dup.isCompleted, isFalse);

      final all = await repo.getActivitiesForDate(date);
      expect(all.length, 2);
    });

    test(
      'moveActivity updates date and times while checking overlaps',
      () async {
        await repo.saveActivity(
          Activity(
            id: 'move-target',
            title: 'Gym Workout',
            category: ActivityCategory.rest,
            date: date,
            startMinute: 600,
            endMinute: 700,
          ),
        );

        final tomorrow = date.add(const Duration(days: 1));
        await repo.moveActivity(
          'move-target',
          newDate: tomorrow,
          newStartMinute: 1000,
          newEndMinute: 1080,
        );

        final todayList = await repo.getActivitiesForDate(date);
        expect(todayList.isEmpty, isTrue);

        final tomorrowList = await repo.getActivitiesForDate(tomorrow);
        expect(tomorrowList.length, 1);
        expect(tomorrowList.first.startMinute, 1000);
        expect(tomorrowList.first.endMinute, 1080);
      },
    );
  });

  group('Daily Time Accounting & Duration Calculations', () {
    test(
      'calculateDayMetrics accurately calculates duration-based percentages and categories',
      () {
        final activities = [
          Activity(
            id: '1',
            title: 'College Systems',
            category: ActivityCategory.college,
            date: DateTime(2026, 10, 28),
            startMinute: 540, // 09:00
            endMinute: 720, // 12:00 -> 180 mins
            isCompleted: true,
          ),
          Activity(
            id: '2',
            title: 'Lunch',
            category: ActivityCategory.meals,
            date: DateTime(2026, 10, 28),
            startMinute: 720,
            endMinute: 780, // 60 mins
            isCompleted: true,
          ),
          Activity(
            id: '3',
            title: 'Flutter Coding',
            category: ActivityCategory.coding,
            date: DateTime(2026, 10, 28),
            startMinute: 840,
            endMinute: 1080, // 240 mins
            isCompleted: false,
          ),
        ];

        final metrics = calculateDayMetrics(activities);

        // Total planned: 180 + 60 + 240 = 480 mins (8 hours)
        expect(metrics.totalPlannedMinutes, 480);
        expect(metrics.plannedDurationFormatted, '8h');

        // Completed: 180 + 60 = 240 mins (4 hours)
        expect(metrics.completedMinutes, 240);
        expect(metrics.completedDurationFormatted, '4h');

        // Remaining: 240 mins
        expect(metrics.remainingMinutes, 240);
        expect(metrics.remainingDurationFormatted, '4h');

        // Tasks count
        expect(metrics.totalActivities, 3);
        expect(metrics.completedActivities, 2);
        expect(metrics.remainingActivities, 1);

        // Duration-based completion ratio: 240 / 480 = 50%
        expect(metrics.completionRatio, 0.5);
        expect(metrics.completionPercent, 50);

        // Free time: 1440 - 480 = 960 mins (16h)
        expect(metrics.freeMinutes, 960);
        expect(metrics.freeDurationFormatted, '16h');

        // Category breakdown
        expect(metrics.categoryAllocations.length, 3);
        expect(
          metrics.categoryAllocations[0].category,
          ActivityCategory.coding,
        );
        expect(metrics.categoryAllocations[0].minutes, 240);
        expect(metrics.categoryAllocations[0].percentageRound, 50); // 240/480
      },
    );
  });
}
