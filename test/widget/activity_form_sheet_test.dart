import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/shared/widgets/activity_form_sheet.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';
import '../helpers/fake_activity_repository.dart';

void main() {
  testWidgets('ActivityFormSheet validates required title field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeActivityRepository();
    final testDate = DateTime(2026, 10, 24);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(fakeRepo),
          currentMinuteProvider.overrideWith((ref) => Stream.value(600)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ActivityFormSheet(
              initialDate: testDate,
              initialStartMinute: 540,
              initialEndMinute: 600,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New Activity'), findsOneWidget);
    expect(find.text('Schedule Activity'), findsOneWidget);

    // Tap submit button with empty title
    await tester.tap(find.text('Schedule Activity'));
    await tester.pumpAndSettle();

    // Verify validation error message
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(fakeRepo.saved.isEmpty, isTrue);

    // Enter title and submit
    await tester.enterText(
      find.byType(TextFormField).first,
      'Operating Systems Lecture',
    );
    await tester.tap(find.text('Schedule Activity'));
    await tester.pumpAndSettle();

    expect(fakeRepo.saved.length, 1);
    expect(fakeRepo.saved.first.title, 'Operating Systems Lecture');
  });
}
