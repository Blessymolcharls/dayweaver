import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/activity_priority.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';
import 'package:dayweaver/shared/widgets/activity_details_sheet.dart';
import '../helpers/fake_activity_repository.dart';

void main() {
  testWidgets('ActivityDetailsSheet displays full details and action buttons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeActivityRepository();
    final testActivity = Activity(
      id: 'act-detail-1',
      title: 'Machine Learning Seminar',
      category: ActivityCategory.college,
      date: DateTime(2026, 10, 28),
      startMinute: 600, // 10:00
      endMinute: 720, // 12:00
      notes: 'Bring transformer architecture notes.',
      priority: ActivityPriority.high,
      isCompleted: false,
      reminderOffsetMinutes: 15,
    );
    fakeRepo.saved.add(testActivity);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [activityRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ActivityDetailsSheet(activity: testActivity)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Category
    expect(find.text('Machine Learning Seminar'), findsOneWidget);
    expect(find.text('College'), findsOneWidget);

    // Verify Times and Notes
    expect(find.text('10:00 – 12:00 (2h)'), findsOneWidget);
    expect(find.text('Bring transformer architecture notes.'), findsOneWidget);
    expect(find.text('Priority: High'), findsOneWidget);
    expect(find.text('15m before'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Mark as Completed'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Test Duplication action
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pumpAndSettle();

    expect(fakeRepo.saved.length, 2);
    expect(
      fakeRepo.saved.any(
        (a) => a.title.contains('Machine Learning Seminar (Copy)'),
      ),
      isTrue,
    );
  });
}
