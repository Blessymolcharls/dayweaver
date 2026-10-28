import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/today/presentation/today_screen.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

void main() {
  testWidgets('TodayScreen displays header, summary, and timeline activities', (
    tester,
  ) async {
    final testDate = DateTime(2026, 10, 24);
    final mockActivities = [
      Activity(
        id: 'act-1',
        title: 'Machine Learning Lecture',
        category: ActivityCategory.college,
        date: testDate,
        startMinute: 540, // 09:00
        endMinute: 660, // 11:00
        isCompleted: true,
      ),
      Activity(
        id: 'act-2',
        title: 'LeetCode Practice',
        category: ActivityCategory.coding,
        date: testDate,
        startMinute: 720, // 12:00
        endMinute: 840, // 14:00
        isCompleted: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith((ref) => testDate),
          activitiesForSelectedDateProvider.overrideWith(
            (ref) => Stream.value(mockActivities),
          ),
          databaseInitializerProvider.overrideWith((ref) async {}),
          currentMinuteProvider.overrideWith((ref) => Stream.value(600)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TodayScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Summary Card components
    expect(find.text('Day Flow'), findsOneWidget);
    expect(find.text('PLANNED'), findsOneWidget);
    expect(find.text('ACCOMPLISHED'), findsOneWidget);

    // Verify Add Activity FAB
    expect(find.text('Add Activity'), findsOneWidget);

    // Verify scheduled activities appear in timeline
    expect(find.text('Machine Learning Lecture'), findsOneWidget);
    expect(find.text('LeetCode Practice'), findsOneWidget);

    // Verify unscheduled free periods appear
    expect(find.textContaining('Unscheduled'), findsWidgets);
  });
}
