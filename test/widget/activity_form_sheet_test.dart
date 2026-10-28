import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/shared/widgets/activity_form_sheet.dart';
import 'package:dayweaver/features/schedule/data/activity_repository.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

class FakeActivityRepository implements ActivityRepository {
  final List<Activity> saved = [];

  @override
  Future<int> countActivities() async => saved.length;

  @override
  Future<void> deleteActivity(String id) async =>
      saved.removeWhere((a) => a.id == id);

  @override
  Future<Activity?> getActivityById(String id) async =>
      saved.where((a) => a.id == id).firstOrNull;

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async => saved;

  @override
  Future<void> saveActivity(Activity activity) async {
    saved.removeWhere((a) => a.id == activity.id);
    saved.add(activity);
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {}

  @override
  Stream<List<Activity>> watchActivitiesForDate(DateTime date) =>
      Stream.value(saved);
}

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
