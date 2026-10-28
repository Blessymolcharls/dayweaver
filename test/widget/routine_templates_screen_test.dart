import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayweaver/core/theme/app_theme.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:dayweaver/features/schedule/domain/conflict_strategy.dart';
import 'package:dayweaver/features/schedule/domain/routine_template.dart';
import 'package:dayweaver/features/schedule/domain/routine_template_block.dart';
import 'package:dayweaver/features/schedule/presentation/activity_providers.dart';
import 'package:dayweaver/features/schedule/presentation/routine_templates_screen.dart';

void main() {
  testWidgets(
    'RoutineTemplatesScreen lists templates and allows opening apply sheet',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTemplates = [
        RoutineTemplate(
          id: 'tmpl-1',
          name: 'College Day',
          description: 'Standard weekday lecture pattern.',
          blocks: [
            const RoutineTemplateBlock(
              id: 'b-1',
              templateId: 'tmpl-1',
              title: 'Morning Systems Lecture',
              category: ActivityCategory.college,
              startMinute: 540,
              endMinute: 660,
            ),
            const RoutineTemplateBlock(
              id: 'b-2',
              templateId: 'tmpl-1',
              title: 'Lunch',
              category: ActivityCategory.meals,
              startMinute: 720,
              endMinute: 780,
            ),
          ],
        ),
        RoutineTemplate(
          id: 'tmpl-2',
          name: 'Weekend Recharge',
          description: 'Light schedule with outdoor time.',
          blocks: [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routineTemplatesStreamProvider.overrideWith(
              (ref) => Stream.value(mockTemplates),
            ),
            databaseInitializerProvider.overrideWith((ref) async {}),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RoutineTemplatesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Template Titles
      expect(find.text('College Day'), findsOneWidget);
      expect(find.text('Weekend Recharge'), findsOneWidget);

      // Verify Block counts
      expect(find.text('2 blocks'), findsOneWidget);
      expect(find.text('0 blocks'), findsOneWidget);

      // Verify Apply to Day button opens ApplyRoutineSheet
      expect(find.text('Apply to Day'), findsWidgets);
      await tester.tap(find.text('Apply to Day').first);
      await tester.pumpAndSettle();

      expect(find.text('Apply Routine'), findsOneWidget);
      expect(
        find.text(ConflictStrategy.skipConflicts.displayName),
        findsOneWidget,
      );
      expect(find.text(ConflictStrategy.overwrite.displayName), findsOneWidget);
      expect(
        find.text(ConflictStrategy.abortOnConflict.displayName),
        findsOneWidget,
      );
    },
  );
}
