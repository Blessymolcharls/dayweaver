import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayweaver/core/database/app_database.dart';
import 'package:dayweaver/features/goals/data/drift_goal_repository.dart';
import 'package:dayweaver/features/goals/domain/goal.dart';
import 'package:dayweaver/features/goals/domain/goal_category.dart';
import 'package:dayweaver/features/goals/domain/goal_milestone.dart';
import 'package:dayweaver/features/goals/domain/goal_status.dart';
import 'package:dayweaver/features/schedule/data/drift_activity_repository.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/activity_priority.dart';

void main() {
  late AppDatabase db;
  late DriftGoalRepository goalRepo;
  late DriftActivityRepository activityRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    goalRepo = DriftGoalRepository(db);
    activityRepo = DriftActivityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Database schema version is 4', () {
    expect(db.schemaVersion, 4);
  });

  group('DriftGoalRepository SQLite Operations', () {
    test('Persists, retrieves, and watches goals in SQLite', () async {
      final goal = Goal(
        id: 'drift_g1',
        title: 'Master Rust Systems',
        category: GoalCategory.coding,
        status: GoalStatus.active,
        targetValue: 40.0,
        currentValue: 12.0,
        unit: 'chapters',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await goalRepo.saveGoal(goal);

      final retrieved = await goalRepo.getGoalById('drift_g1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Master Rust Systems');
      expect(retrieved.currentValue, 12.0);
      expect(retrieved.category, GoalCategory.coding);

      final allGoals = await goalRepo.getGoals();
      expect(allGoals.length, 1);
    });

    test(
      'Records progress updates and updates goal current value atomically',
      () async {
        final goal = Goal(
          id: 'drift_prog',
          title: 'Solve LeetCode Top 150',
          category: GoalCategory.coding,
          status: GoalStatus.active,
          targetValue: 150.0,
          currentValue: 30.0,
          unit: 'problems',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await goalRepo.saveGoal(goal);

        // Incremental +15
        await goalRepo.recordProgressUpdate(
          goalId: 'drift_prog',
          changeAmount: 15.0,
          isIncremental: true,
          note: 'Completed Graphs section',
        );

        var updated = await goalRepo.getGoalById('drift_prog');
        expect(updated!.currentValue, 45.0);

        // Absolute update =150 (should auto-complete)
        await goalRepo.recordProgressUpdate(
          goalId: 'drift_prog',
          changeAmount: 150.0,
          isIncremental: false,
          note: 'Completed all 150',
        );

        updated = await goalRepo.getGoalById('drift_prog');
        expect(updated!.currentValue, 150.0);
        expect(updated.status, GoalStatus.completed);

        final history = await goalRepo.getProgressUpdates('drift_prog');
        expect(history.length, 2);
      },
    );

    test('Milestone persistence and cascade deletion on goal delete', () async {
      final goal = Goal(
        id: 'drift_parent',
        title: 'Launch Mobile App',
        category: GoalCategory.projects,
        status: GoalStatus.active,
        targetValue: 100.0,
        currentValue: 20.0,
        unit: 'percent',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await goalRepo.saveGoal(goal);

      final milestone = GoalMilestone(
        id: 'ms_1',
        goalId: 'drift_parent',
        title: 'MVP UI Design',
        orderIndex: 0,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      await goalRepo.saveMilestone(milestone);

      var milestones = await goalRepo.getMilestones('drift_parent');
      expect(milestones.length, 1);
      expect(milestones.first.title, 'MVP UI Design');

      // Toggle milestone completion
      await goalRepo.toggleMilestone('ms_1', true);
      milestones = await goalRepo.getMilestones('drift_parent');
      expect(milestones.first.isCompleted, isTrue);

      // Delete goal - milestone should be cascade-deleted
      await goalRepo.deleteGoal('drift_parent');
      final remainingGoals = await goalRepo.getGoals();
      expect(remainingGoals.isEmpty, isTrue);

      final remainingMilestones = await goalRepo.getMilestones('drift_parent');
      expect(remainingMilestones.isEmpty, isTrue);
    });

    test('Activity-Goal SQLite junction linking works safely', () async {
      // 1. Create activity in SQLite
      final activity = Activity(
        id: 'act_drift_1',
        title: 'LeetCode Practice Session',
        category: ActivityCategory.coding,
        date: DateTime(2026, 10, 29),
        startMinute: 600,
        endMinute: 660,
        priority: ActivityPriority.high,
      );
      await activityRepo.saveActivity(activity);

      // 2. Create goal in SQLite
      final goal = Goal(
        id: 'goal_drift_1',
        title: 'Algorithms Prep',
        category: GoalCategory.career,
        status: GoalStatus.active,
        targetValue: 100.0,
        currentValue: 10.0,
        unit: 'problems',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await goalRepo.saveGoal(goal);

      // 3. Link them
      await goalRepo.linkActivityToGoal('act_drift_1', 'goal_drift_1');

      final linkedGoals = await goalRepo.getLinkedGoalsForActivity(
        'act_drift_1',
      );
      expect(linkedGoals.length, 1);
      expect(linkedGoals.first.id, 'goal_drift_1');

      final linkedActIds = await goalRepo.getLinkedActivityIdsForGoal(
        'goal_drift_1',
      );
      expect(linkedActIds, contains('act_drift_1'));

      // 4. Unlink
      await goalRepo.unlinkActivityFromGoal('act_drift_1', 'goal_drift_1');
      final unlinkedGoals = await goalRepo.getLinkedGoalsForActivity(
        'act_drift_1',
      );
      expect(unlinkedGoals.isEmpty, isTrue);
    });
  });
}
