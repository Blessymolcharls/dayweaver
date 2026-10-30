import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/goals/domain/goal.dart';
import 'package:dayweaver/features/goals/domain/goal_category.dart';
import 'package:dayweaver/features/goals/domain/goal_milestone.dart';
import 'package:dayweaver/features/goals/domain/goal_status.dart';
import 'package:dayweaver/features/goals/presentation/goal_detail_screen.dart';
import 'package:dayweaver/features/goals/presentation/goal_providers.dart';
import 'package:dayweaver/features/goals/presentation/goals_screen.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

import '../helpers/fake_goal_repository.dart';

void main() {
  late FakeGoalRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeGoalRepository();
  });

  Widget buildTestApp({Widget child = const GoalsScreen()}) {
    return ProviderScope(
      overrides: [
        databaseInitializerProvider.overrideWith((ref) async {}),
        goalRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  testWidgets('GoalsScreen renders empty state when no goals exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Goals & Milestones'), findsOneWidget);
    expect(find.text('Focus & Progress'), findsOneWidget);
    expect(find.text('Set your first goal'), findsOneWidget);
    expect(find.text('New Goal'), findsOneWidget);
  });

  testWidgets('GoalsScreen lists goals with summary banner and filter chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final goal1 = Goal(
      id: 'g_w1',
      title: 'Master Flutter Architecture',
      category: GoalCategory.coding,
      status: GoalStatus.active,
      targetValue: 40.0,
      currentValue: 10.0,
      unit: 'hours',
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final goal2 = Goal(
      id: 'g_w2',
      title: 'Machine Learning Term Paper',
      category: GoalCategory.academics,
      status: GoalStatus.completed,
      targetValue: 1.0,
      currentValue: 1.0,
      unit: 'papers',
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await fakeRepo.saveGoal(goal1);
    await fakeRepo.saveGoal(goal2);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Master Flutter Architecture'), findsOneWidget);
    expect(find.text('Machine Learning Term Paper'), findsOneWidget);
    expect(find.text('Coding & Skills'), findsOneWidget);
    expect(find.text('Academics'), findsOneWidget);

    // Filter by Active
    await tester.tap(find.text('Active (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Master Flutter Architecture'), findsOneWidget);
    expect(find.text('Machine Learning Term Paper'), findsNothing);

    // Filter by Completed
    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Master Flutter Architecture'), findsNothing);
    expect(find.text('Machine Learning Term Paper'), findsOneWidget);
  });

  testWidgets('Opens RecordProgressSheet and records progress successfully', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final goal = Goal(
      id: 'g_rec',
      title: '50 LeetCode Problems',
      category: GoalCategory.coding,
      status: GoalStatus.active,
      targetValue: 50.0,
      currentValue: 10.0,
      unit: 'problems',
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeRepo.saveGoal(goal);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Tap quick progress icon button on the card
    final recordBtn = find.byTooltip('Record Progress');
    expect(recordBtn, findsOneWidget);
    await tester.tap(recordBtn);
    await tester.pumpAndSettle();

    // Verify Record Progress sheet opened
    expect(find.text('Update Progress'), findsOneWidget);
    expect(find.text('Add Progress (+)'), findsOneWidget);

    // Enter progress value
    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '5');
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('Save Progress Update'));
    await tester.pumpAndSettle();

    // Verify value updated
    final updated = await fakeRepo.getGoalById('g_rec');
    expect(updated!.currentValue, 15.0);
  });

  testWidgets('GoalDetailScreen renders metadata, milestones, and updates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final goal = Goal(
      id: 'g_detail',
      title: 'Deep Learning Specialization',
      description: 'Finish all 5 courses on Coursera',
      category: GoalCategory.coding,
      status: GoalStatus.active,
      targetValue: 5.0,
      currentValue: 2.0,
      unit: 'courses',
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await fakeRepo.saveGoal(goal);

    final milestone = GoalMilestone(
      id: 'm_detail_1',
      goalId: 'g_detail',
      title: 'Neural Networks & Deep Learning',
      orderIndex: 0,
      isCompleted: true,
      createdAt: DateTime.now(),
    );
    await fakeRepo.saveMilestone(milestone);

    await tester.pumpWidget(
      buildTestApp(child: const GoalDetailScreen(goalId: 'g_detail')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deep Learning Specialization'), findsWidgets);
    expect(find.text('Finish all 5 courses on Coursera'), findsOneWidget);
    expect(find.text('Neural Networks & Deep Learning'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('Progress History'), findsOneWidget);
  });
}
