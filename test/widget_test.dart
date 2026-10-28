import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/main.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';

void main() {
  testWidgets('DayweaverApp loads and navigates between tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseInitializerProvider.overrideWith((ref) async {}),
          activitiesForSelectedDateProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          activitiesForPlannerDateProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          plannerActivityDatesProvider.overrideWith(
            (ref) => Future.value(<DateTime>{}),
          ),
          currentMinuteProvider.overrideWith((ref) => Stream.value(600)),
        ],
        child: const DayweaverApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Default Tab is Today
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);

    // Switch to Planner tab
    await tester.tap(find.text('Planner'));
    await tester.pumpAndSettle();

    expect(find.text('Routines'), findsOneWidget);

    // Switch to Goals tab
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    expect(find.text('Planned for Next Milestone'), findsOneWidget);

    // Switch to Insights tab
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Insights'), findsOneWidget);

    // Switch back to Today
    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    expect(find.text('Day Flow'), findsOneWidget);
  });
}
