import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/planner/presentation/planner_screen.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

void main() {
  testWidgets(
    'PlannerScreen displays monthly calendar, summary, and daily schedule',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDate = DateTime(2026, 10, 28);
      final mockActivities = [
        Activity(
          id: 'p-1',
          title: 'Distributed Systems',
          category: ActivityCategory.college,
          date: testDate,
          startMinute: 540,
          endMinute: 660,
          isCompleted: true,
        ),
        Activity(
          id: 'p-2',
          title: 'Algorithms Revision',
          category: ActivityCategory.personal,
          date: testDate,
          startMinute: 720,
          endMinute: 840,
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerSelectedDateProvider.overrideWith((ref) => testDate),
            activitiesForPlannerDateProvider.overrideWith(
              (ref) => Stream.value(mockActivities),
            ),
            plannerActivityDatesProvider.overrideWith(
              (ref) => Future.value({testDate}),
            ),
            databaseInitializerProvider.overrideWith((ref) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar and Navigation Actions
      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Routines'), findsOneWidget);

      // Verify Calendar Days of week
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsWidgets);
      expect(find.text('W'), findsOneWidget);

      // Verify Day Summary Card is rendered
      expect(find.text('Day Flow'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);

      // Verify Scheduled activities appear
      expect(find.text('Distributed Systems'), findsOneWidget);
      expect(find.text('Algorithms Revision'), findsOneWidget);

      // Verify FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );

  testWidgets(
    'PlannerScreen displays calm empty state when no activities are scheduled',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyDate = DateTime(2026, 11, 5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannerSelectedDateProvider.overrideWith((ref) => emptyDate),
            activitiesForPlannerDateProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            plannerActivityDatesProvider.overrideWith(
              (ref) => Future.value(<DateTime>{}),
            ),
            databaseInitializerProvider.overrideWith((ref) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Empty State message and quick action buttons
      expect(find.text('No Activities Scheduled'), findsOneWidget);
      expect(find.text('Apply Routine'), findsOneWidget);
      expect(find.text('Copy Schedule'), findsOneWidget);
      expect(find.text('Add Activity'), findsOneWidget);
    },
  );
}
