import 'package:dayweaver/features/goals/domain/goal.dart';
import 'package:dayweaver/features/goals/domain/goal_category.dart';
import 'package:dayweaver/features/goals/domain/goal_milestone.dart';
import 'package:dayweaver/features/goals/domain/goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_goal_repository.dart';

void main() {
  group('Goal Domain Model & Calculations', () {
    test('Calculates numeric progress correctly with valid target', () {
      final goal = Goal(
        id: 'g1',
        title: 'Read 20 Books',
        category: GoalCategory.personal,
        status: GoalStatus.active,
        targetValue: 20.0,
        currentValue: 5.0,
        unit: 'books',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressRatio, closeTo(0.25, 0.001));
      expect(goal.progressPercent, 25);
      expect(goal.remainingValue, closeTo(15.0, 0.001));
      expect(goal.formattedCurrent, '5 books');
      expect(goal.formattedTarget, '20 books');
    });

    test('Clamps progress to 1.0 (100%) when current exceeds target', () {
      final goal = Goal(
        id: 'g2',
        title: 'Run 100 km',
        category: GoalCategory.health,
        status: GoalStatus.active,
        targetValue: 100.0,
        currentValue: 120.0,
        unit: 'km',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressRatio, 1.0);
      expect(goal.progressPercent, 100);
      expect(goal.remainingValue, 0.0);
    });

    test(
      'Protects against division by zero when targetValue is zero or negative',
      () {
        final goalZero = Goal(
          id: 'g3',
          title: 'Zero Target Test',
          category: GoalCategory.custom,
          status: GoalStatus.active,
          targetValue: 0.0,
          currentValue: 0.0,
          unit: 'items',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(goalZero.progressRatio, 0.0);
        expect(goalZero.progressPercent, 0);
        expect(goalZero.remainingValue, 0.0);
      },
    );

    test('Calculates daysRemaining correctly relative to today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final inThreeDays = today.add(const Duration(days: 3));

      final goalWithDeadline = Goal(
        id: 'g4',
        title: 'Project Submission',
        category: GoalCategory.projects,
        status: GoalStatus.active,
        targetValue: 1.0,
        currentValue: 0.0,
        unit: 'submissions',
        startDate: today,
        targetDate: inThreeDays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goalWithDeadline.daysRemaining, 3);
      expect(goalWithDeadline.isApproachingDeadline(withinDays: 7), isTrue);
      expect(goalWithDeadline.isApproachingDeadline(withinDays: 2), isFalse);
    });

    test('Milestones independent completion ratio calculates properly', () {
      final milestones = [
        GoalMilestone(
          id: 'm1',
          goalId: 'g5',
          title: 'Phase 1',
          orderIndex: 0,
          isCompleted: true,
          createdAt: DateTime.now(),
        ),
        GoalMilestone(
          id: 'm2',
          goalId: 'g5',
          title: 'Phase 2',
          orderIndex: 1,
          isCompleted: true,
          createdAt: DateTime.now(),
        ),
        GoalMilestone(
          id: 'm3',
          goalId: 'g5',
          title: 'Phase 3',
          orderIndex: 2,
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
        GoalMilestone(
          id: 'm4',
          goalId: 'g5',
          title: 'Phase 4',
          orderIndex: 3,
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      ];

      final goal = Goal(
        id: 'g5',
        title: 'Capstone Project',
        category: GoalCategory.projects,
        status: GoalStatus.active,
        targetValue: 100.0,
        currentValue: 10.0,
        unit: 'percent',
        startDate: DateTime(2026, 1, 1),
        milestones: milestones,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.milestonesCompletedCount, 2);
      expect(goal.milestonesTotalCount, 4);
      expect(goal.milestoneProgressPercent, 50);
      // Numeric progress remains distinct from milestone progress
      expect(goal.progressPercent, 10);
    });

    test('Status transitions work correctly', () {
      expect(GoalStatus.active.canPause, isTrue);
      expect(GoalStatus.active.canComplete, isTrue);
      expect(GoalStatus.active.canArchive, isTrue);

      expect(GoalStatus.paused.canResume, isTrue);
      expect(GoalStatus.completed.canArchive, isTrue);
      expect(GoalStatus.archived.canArchive, isFalse);
    });
  });

  group('FakeGoalRepository Operations & Linking', () {
    late FakeGoalRepository repo;

    setUp(() {
      repo = FakeGoalRepository();
    });

    test('Saves, retrieves, and updates goals', () async {
      final goal = Goal(
        id: 'test_g1',
        title: 'Master Flutter',
        category: GoalCategory.coding,
        status: GoalStatus.active,
        targetValue: 50.0,
        currentValue: 10.0,
        unit: 'hours',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveGoal(goal);
      final retrieved = await repo.getGoalById('test_g1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Master Flutter');
      expect(retrieved.currentValue, 10.0);

      await repo.updateGoalStatus('test_g1', GoalStatus.completed);
      final completed = await repo.getGoalById('test_g1');
      expect(completed!.status, GoalStatus.completed);
    });

    test('Records incremental and absolute progress updates', () async {
      final goal = Goal(
        id: 'test_prog',
        title: 'LeetCode 50',
        category: GoalCategory.coding,
        status: GoalStatus.active,
        targetValue: 50.0,
        currentValue: 20.0,
        unit: 'problems',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.saveGoal(goal);

      // Incremental update (+5)
      await repo.recordProgressUpdate(
        goalId: 'test_prog',
        changeAmount: 5.0,
        isIncremental: true,
        note: 'Solved 5 tree questions',
      );

      var updated = await repo.getGoalById('test_prog');
      expect(updated!.currentValue, 25.0);

      // Absolute update (=40)
      await repo.recordProgressUpdate(
        goalId: 'test_prog',
        changeAmount: 40.0,
        isIncremental: false,
        note: 'Recalculated count',
      );

      updated = await repo.getGoalById('test_prog');
      expect(updated!.currentValue, 40.0);

      final history = await repo.getProgressUpdates('test_prog');
      expect(history.length, 2);
    });

    test('Milestone CRUD and toggle completion', () async {
      final milestone = GoalMilestone(
        id: 'm_test_1',
        goalId: 'g_parent',
        title: 'Finish API specs',
        orderIndex: 0,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await repo.saveMilestone(milestone);
      final milestones = await repo.getMilestones('g_parent');
      expect(milestones.length, 1);
      expect(milestones.first.isCompleted, isFalse);

      await repo.toggleMilestone('m_test_1', true);
      final toggled = await repo.getMilestones('g_parent');
      expect(toggled.first.isCompleted, isTrue);
      expect(toggled.first.completedAt, isNotNull);

      await repo.deleteMilestone('m_test_1');
      final remaining = await repo.getMilestones('g_parent');
      expect(remaining.isEmpty, isTrue);
    });

    test('Activity-Goal bidirectional linking and unlinking', () async {
      const activityId = 'act_100';
      const goalId = 'goal_200';

      final goal = Goal(
        id: goalId,
        title: 'Study OS',
        category: GoalCategory.academics,
        status: GoalStatus.active,
        targetValue: 10.0,
        currentValue: 2.0,
        unit: 'chapters',
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.saveGoal(goal);

      await repo.linkActivityToGoal(activityId, goalId);

      final linkedGoals = await repo.getLinkedGoalsForActivity(activityId);
      expect(linkedGoals.length, 1);
      expect(linkedGoals.first.id, goalId);

      final linkedActIds = await repo.getLinkedActivityIdsForGoal(goalId);
      expect(linkedActIds, contains(activityId));

      await repo.unlinkActivityFromGoal(activityId, goalId);
      final unlinked = await repo.getLinkedGoalsForActivity(activityId);
      expect(unlinked.isEmpty, isTrue);
    });

    test(
      'Deleting a goal cascades and cleans up milestones, updates, and links',
      () async {
        const goalId = 'g_cascade';
        final goal = Goal(
          id: goalId,
          title: 'Cascade Test Goal',
          category: GoalCategory.projects,
          status: GoalStatus.active,
          targetValue: 10.0,
          currentValue: 1.0,
          unit: 'milestones',
          startDate: DateTime(2026, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.saveGoal(goal);

        await repo.saveMilestone(
          GoalMilestone(
            id: 'm_casc',
            goalId: goalId,
            title: 'Milestone 1',
            orderIndex: 0,
            createdAt: DateTime.now(),
          ),
        );

        await repo.recordProgressUpdate(
          goalId: goalId,
          changeAmount: 2.0,
          isIncremental: true,
        );

        await repo.linkActivityToGoal('act_casc', goalId);

        // Verify created
        expect((await repo.getMilestones(goalId)).length, 1);
        expect((await repo.getProgressUpdates(goalId)).length, 1);
        expect((await repo.getLinkedGoalsForActivity('act_casc')).length, 1);

        // Delete goal
        await repo.deleteGoal(goalId);

        expect(await repo.getGoalById(goalId), isNull);
        expect((await repo.getMilestones(goalId)).isEmpty, isTrue);
        expect((await repo.getProgressUpdates(goalId)).isEmpty, isTrue);
        expect(
          (await repo.getLinkedGoalsForActivity('act_casc')).isEmpty,
          isTrue,
        );
      },
    );
  });
}
