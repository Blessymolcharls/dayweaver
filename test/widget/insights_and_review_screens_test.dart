import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/notifications/notification_providers.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/insights/presentation/insights_screen.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';
import 'package:dayweaver/features/settings/presentation/settings_screen.dart';
import 'package:dayweaver/features/today/presentation/daily_review_screen.dart';
import '../helpers/fake_activity_repository.dart';
import '../unit/notification_service_test.dart';

void main() {
  testWidgets('InsightsScreen renders weekly progress and daily overview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final DateTime monday = DateTime(2026, 10, 26);
    final List<Activity> mockWeek = [
      Activity(
        id: 'ins-1',
        title: 'Computer Architecture',
        category: ActivityCategory.college,
        date: monday,
        startMinute: 540,
        endMinute: 660,
        isCompleted: true,
      ),
      Activity(
        id: 'ins-2',
        title: 'Flutter UI Engineering',
        category: ActivityCategory.coding,
        date: DateTime(2026, 10, 27),
        startMinute: 720,
        endMinute: 900,
        isCompleted: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedWeekStartProvider.overrideWith((Ref ref) => monday),
          weeklyActivitiesProvider.overrideWith(
            (Ref ref) => Stream.value(mockWeek),
          ),
          databaseInitializerProvider.overrideWith((Ref ref) async {}),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InsightsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Weekly Insights'), findsOneWidget);
    expect(find.text('Weekly Progress'), findsOneWidget);
    expect(find.text('Daily Overview'), findsOneWidget);
    expect(find.text('Time Allocation by Category'), findsOneWidget);
    expect(find.text('Activity Counts'), findsOneWidget);
    expect(find.text('Completed Tasks'), findsOneWidget);
  });

  testWidgets('DailyReviewScreen displays flow summary and unfinished tasks', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final FakeActivityRepository fakeRepo = FakeActivityRepository();
    final DateTime testDate = DateTime(2026, 10, 28);

    final Activity completedAct = Activity(
      id: 'rev-1',
      title: 'Operating Systems Lab',
      category: ActivityCategory.college,
      date: testDate,
      startMinute: 600,
      endMinute: 720,
      isCompleted: true,
    );

    final Activity unfinishedAct = Activity(
      id: 'rev-2',
      title: 'Graph Algorithms Practice',
      category: ActivityCategory.coding,
      date: testDate,
      startMinute: 800,
      endMinute: 920,
      isCompleted: false,
    );

    fakeRepo.saved.addAll([completedAct, unfinishedAct]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(fakeRepo),
          databaseInitializerProvider.overrideWith((Ref ref) async {}),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: DailyReviewScreen(initialDate: testDate),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Daily Review'), findsOneWidget);
    expect(find.text('Day Flow Summary'), findsOneWidget);
    expect(find.text('Operating Systems Lab'), findsOneWidget);
    expect(find.text('Graph Algorithms Practice'), findsOneWidget);
    expect(find.text('Move to Tomorrow'), findsOneWidget);
    expect(find.text('Daily Reflection & Notes'), findsOneWidget);
    expect(find.text('Save Reflection'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays notification permission and guidance', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final TestNotificationService mockNotif = TestNotificationService();
    mockNotif.permissionsGranted = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(mockNotif),
          databaseInitializerProvider.overrideWith((Ref ref) async {}),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Notifications & Reminders'), findsOneWidget);
    expect(find.text('Enabled'), findsOneWidget);
    expect(find.text('Recurring Activities'), findsOneWidget);
    expect(find.text('Daily Review'), findsOneWidget);
    expect(find.text('Routine Templates'), findsOneWidget);
    expect(find.text('About Dayweaver'), findsOneWidget);
    expect(find.text('1.0.0 (Milestone 3)'), findsOneWidget);
  });
}
