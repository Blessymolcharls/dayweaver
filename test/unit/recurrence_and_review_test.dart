import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayweaver/core/database/app_database.dart';
import 'package:dayweaver/features/schedule/data/drift_activity_repository.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/daily_review.dart';
import 'package:dayweaver/features/schedule/domain/recurrence_rule.dart';
import 'package:dayweaver/features/schedule/domain/weekly_metrics.dart';

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

  group('RecurrenceRule Domain Logic', () {
    final DateTime baseDate = DateTime(2026, 10, 26); // Monday

    test('daily recurrence matches all days within start and end limits', () {
      final RecurrenceRule rule = RecurrenceRule(
        id: 'rule-daily-1',
        title: 'Morning Meditation',
        category: ActivityCategory.rest,
        startMinute: 360,
        endMinute: 390,
        recurrenceType: RecurrenceType.daily,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        startDate: baseDate,
        endDate: baseDate.add(const Duration(days: 10)),
      );

      expect(rule.matchesDate(baseDate), isTrue); // Monday
      expect(
        rule.matchesDate(baseDate.add(const Duration(days: 5))),
        isTrue,
      ); // Saturday
      expect(
        rule.matchesDate(baseDate.subtract(const Duration(days: 1))),
        isFalse,
      ); // Before start
      expect(
        rule.matchesDate(baseDate.add(const Duration(days: 20))),
        isFalse,
      ); // After end
    });

    test('weekdays recurrence matches Mon-Fri and excludes Sat-Sun', () {
      final RecurrenceRule rule = RecurrenceRule(
        id: 'rule-weekdays-1',
        title: 'Algorithms Revision',
        category: ActivityCategory.coding,
        startMinute: 540,
        endMinute: 660,
        recurrenceType: RecurrenceType.weekdays,
        daysOfWeek: const [1, 2, 3, 4, 5],
        startDate: baseDate,
      );

      expect(rule.matchesDate(DateTime(2026, 10, 26)), isTrue); // Mon
      expect(rule.matchesDate(DateTime(2026, 10, 27)), isTrue); // Tue
      expect(rule.matchesDate(DateTime(2026, 10, 30)), isTrue); // Fri
      expect(rule.matchesDate(DateTime(2026, 10, 31)), isFalse); // Sat
      expect(rule.matchesDate(DateTime(2026, 11, 1)), isFalse); // Sun
    });

    test('custom days recurrence matches only specified weekdays', () {
      final RecurrenceRule rule = RecurrenceRule(
        id: 'rule-custom-1',
        title: 'Gym Workout',
        category: ActivityCategory.rest,
        startMinute: 1020,
        endMinute: 1080,
        recurrenceType: RecurrenceType.custom,
        daysOfWeek: const [1, 3, 5], // Mon, Wed, Fri
        startDate: baseDate,
      );

      expect(rule.matchesDate(DateTime(2026, 10, 26)), isTrue); // Mon (1)
      expect(rule.matchesDate(DateTime(2026, 10, 27)), isFalse); // Tue (2)
      expect(rule.matchesDate(DateTime(2026, 10, 28)), isTrue); // Wed (3)
      expect(rule.matchesDate(DateTime(2026, 10, 29)), isFalse); // Thu (4)
      expect(rule.matchesDate(DateTime(2026, 10, 30)), isTrue); // Fri (5)
    });

    test('disabled rule never matches', () {
      final RecurrenceRule rule = RecurrenceRule(
        id: 'rule-disabled-1',
        title: 'Optional Club Meet',
        category: ActivityCategory.personal,
        startMinute: 1000,
        endMinute: 1100,
        recurrenceType: RecurrenceType.daily,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
        startDate: baseDate,
        isEnabled: false,
      );

      expect(rule.matchesDate(baseDate), isFalse);
    });
  });

  group('Drift SQLite Recurrence Operations & Idempotency', () {
    final DateTime targetMonday = DateTime(2026, 10, 26);

    test('saves and retrieves recurrence rules', () async {
      final RecurrenceRule rule = RecurrenceRule(
        id: 'rec-rule-test',
        title: 'Evening System Design Reading',
        category: ActivityCategory.coding,
        startMinute: 1200,
        endMinute: 1260,
        recurrenceType: RecurrenceType.weekdays,
        daysOfWeek: const [1, 2, 3, 4, 5],
        startDate: targetMonday,
        notes: 'Read Designing Data-Intensive Applications',
      );

      await repo.saveRecurrenceRule(rule);

      final RecurrenceRule? retrieved = await repo.getRecurrenceRuleById(
        'rec-rule-test',
      );
      expect(retrieved, isNotNull);
      expect(retrieved?.title, equals('Evening System Design Reading'));
      expect(retrieved?.daysOfWeek, equals([1, 2, 3, 4, 5]));
      expect(retrieved?.isEnabled, isTrue);

      // Toggle disabled
      await repo.toggleRecurrenceRuleEnabled('rec-rule-test', false);
      final RecurrenceRule? updated = await repo.getRecurrenceRuleById(
        'rec-rule-test',
      );
      expect(updated?.isEnabled, isFalse);
    });

    test(
      'idempotently generates activities without duplicate entries',
      () async {
        final RecurrenceRule rule = RecurrenceRule(
          id: 'rec-rule-idempotent',
          title: 'Daily Standup & Sync',
          category: ActivityCategory.college,
          startMinute: 540, // 09:00
          endMinute: 570, // 09:30
          recurrenceType: RecurrenceType.daily,
          daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
          startDate: targetMonday,
        );
        await repo.saveRecurrenceRule(rule);

        // First run: generates 1 activity
        final int firstRunCount = await repo.generateRecurringActivitiesForDate(
          targetMonday,
        );
        expect(firstRunCount, equals(1));

        final List<Activity> actsAfterFirst = await repo.getActivitiesForDate(
          targetMonday,
        );
        expect(actsAfterFirst.length, equals(1));
        expect(actsAfterFirst.first.title, equals('Daily Standup & Sync'));
        expect(actsAfterFirst.first.isRecurrenceInstance, isTrue);

        // Second run on same date: produces 0 new activities
        final int secondRunCount = await repo
            .generateRecurringActivitiesForDate(targetMonday);
        expect(secondRunCount, equals(0));

        final List<Activity> actsAfterSecond = await repo.getActivitiesForDate(
          targetMonday,
        );
        expect(actsAfterSecond.length, equals(1));
      },
    );

    test(
      'recurrence generation respects existing conflicts and does not overwrite',
      () async {
        // Pre-existing scheduled exam from 09:00 to 11:00
        final Activity existing = Activity(
          id: 'exam-slot',
          title: 'Midterm Exam',
          category: ActivityCategory.college,
          date: targetMonday,
          startMinute: 540,
          endMinute: 660,
        );
        await repo.saveActivity(existing);

        // Recurrence rule trying to occupy 09:30 - 10:30 (overlaps with exam)
        final RecurrenceRule overlappingRule = RecurrenceRule(
          id: 'overlapping-rule',
          title: 'Routine Study Session',
          category: ActivityCategory.personal,
          startMinute: 570,
          endMinute: 630,
          recurrenceType: RecurrenceType.daily,
          daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
          startDate: targetMonday,
        );
        await repo.saveRecurrenceRule(overlappingRule);

        final int generated = await repo.generateRecurringActivitiesForDate(
          targetMonday,
        );
        expect(generated, equals(0)); // Skipped to preserve Midterm Exam

        final List<Activity> current = await repo.getActivitiesForDate(
          targetMonday,
        );
        expect(current.length, equals(1));
        expect(current.first.title, equals('Midterm Exam'));
      },
    );

    test(
      'deleting a generated occurrence creates exception and prevents regeneration',
      () async {
        final RecurrenceRule rule = RecurrenceRule(
          id: 'rule-exception-test',
          title: 'Daily Walk',
          category: ActivityCategory.rest,
          startMinute: 420,
          endMinute: 480,
          recurrenceType: RecurrenceType.daily,
          daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
          startDate: targetMonday,
        );
        await repo.saveRecurrenceRule(rule);

        await repo.generateRecurringActivitiesForDate(targetMonday);
        List<Activity> acts = await repo.getActivitiesForDate(targetMonday);
        expect(acts.length, equals(1));

        // Delete this occurrence
        await repo.deleteActivity(acts.first.id);
        acts = await repo.getActivitiesForDate(targetMonday);
        expect(acts.isEmpty, isTrue);

        // Refresh / reopen date: should not regenerate deleted occurrence
        final int regenerated = await repo.generateRecurringActivitiesForDate(
          targetMonday,
        );
        expect(regenerated, equals(0));

        acts = await repo.getActivitiesForDate(targetMonday);
        expect(acts.isEmpty, isTrue);
      },
    );
  });

  group('Daily Review & Weekly Insights Operations', () {
    final DateTime reviewDate = DateTime(2026, 10, 28);

    test('persists and retrieves daily review records in SQLite', () async {
      final DailyReview review = DailyReview(
        date: reviewDate,
        reflectionNotes: 'Great focus during morning algorithms block.',
        completedTasksCount: 4,
        totalTasksCount: 5,
        completedMinutes: 300,
        totalPlannedMinutes: 420,
      );

      await repo.saveDailyReview(review);

      final DailyReview? loaded = await repo.getDailyReview(reviewDate);
      expect(loaded, isNotNull);
      expect(
        loaded?.reflectionNotes,
        equals('Great focus during morning algorithms block.'),
      );
      expect(loaded?.completedTasksCount, equals(4));
      expect(loaded?.totalPlannedMinutes, equals(420));
      expect(loaded?.completedMinutes, equals(300));
      expect(loaded?.completionPercent, equals(71)); // 300 / 420 = 71.4%
      expect(loaded?.freeMinutes, equals(1020)); // 1440 - 420
    });

    test('WeeklyMetrics aggregates activities across the 7 days accurately', () {
      final DateTime monday = DateTime(2026, 10, 26);
      final DateTime sunday = DateTime(2026, 11, 1);

      final List<Activity> activities = [
        // Monday: 2h planned, 2h completed (College)
        Activity(
          id: 'w-1',
          title: 'Monday Lecture',
          category: ActivityCategory.college,
          date: monday,
          startMinute: 600,
          endMinute: 720,
          isCompleted: true,
        ),
        // Tuesday: 3h planned, 0h completed (Coding)
        Activity(
          id: 'w-2',
          title: 'Tuesday Coding Project',
          category: ActivityCategory.coding,
          date: DateTime(2026, 10, 27),
          startMinute: 720,
          endMinute: 900,
          isCompleted: false,
        ),
        // Wednesday: 1h planned, 1h completed (Rest)
        Activity(
          id: 'w-3',
          title: 'Wednesday Rest',
          category: ActivityCategory.rest,
          date: DateTime(2026, 10, 28),
          startMinute: 1100,
          endMinute: 1160,
          isCompleted: true,
        ),
      ];

      final WeeklyMetrics metrics = WeeklyMetrics.fromActivities(
        startOfWeek: monday,
        endOfWeek: sunday,
        activities: activities,
      );

      // Total planned: 120 + 180 + 60 = 360 min (6h)
      expect(metrics.totalPlannedMinutes, equals(360));
      // Total completed: 120 + 60 = 180 min (3h)
      expect(metrics.totalCompletedMinutes, equals(180));
      // Weekly completion: 180 / 360 = 50%
      expect(metrics.completionPercent, equals(50));
      expect(metrics.completedActivitiesCount, equals(2));
      expect(metrics.unfinishedActivitiesCount, equals(1));

      // Category breakdown
      expect(metrics.categoryMinutes[ActivityCategory.college], equals(120));
      expect(metrics.categoryMinutes[ActivityCategory.coding], equals(180));
      expect(metrics.categoryMinutes[ActivityCategory.rest], equals(60));

      // Percentages: Coding (180/360) = 50%, College (120/360) = 33%, Rest (60/360) = 17%
      expect(metrics.categoryPercentages[ActivityCategory.coding], equals(50));
      expect(metrics.categoryPercentages[ActivityCategory.college], equals(33));
      expect(metrics.categoryPercentages[ActivityCategory.rest], equals(17));

      // 7-day daily breakdown
      expect(metrics.dailyBreakdowns.length, equals(7));
      expect(metrics.dailyBreakdowns[0].plannedMinutes, equals(120));
      expect(metrics.dailyBreakdowns[0].completedMinutes, equals(120));
      expect(metrics.dailyBreakdowns[1].plannedMinutes, equals(180));
      expect(metrics.dailyBreakdowns[1].completedMinutes, equals(0));
    });

    test('WeeklyMetrics handles completely empty week gracefully', () {
      final DateTime monday = DateTime(2026, 11, 2);
      final DateTime sunday = DateTime(2026, 11, 8);

      final WeeklyMetrics emptyMetrics = WeeklyMetrics.fromActivities(
        startOfWeek: monday,
        endOfWeek: sunday,
        activities: const [],
      );

      expect(emptyMetrics.totalPlannedMinutes, equals(0));
      expect(emptyMetrics.totalCompletedMinutes, equals(0));
      expect(emptyMetrics.completionPercent, equals(0));
      expect(emptyMetrics.completedActivitiesCount, equals(0));
      expect(emptyMetrics.unfinishedActivitiesCount, equals(0));
      expect(emptyMetrics.categoryMinutes.isEmpty, isTrue);
      expect(emptyMetrics.categoryPercentages.isEmpty, isTrue);
      expect(emptyMetrics.dailyBreakdowns.length, equals(7));
    });
  });
}
