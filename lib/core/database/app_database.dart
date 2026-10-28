import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/activities_table.dart';
import 'tables/daily_reviews_table.dart';
import 'tables/recurrence_rules_table.dart';
import 'tables/routine_templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ActivitiesTable,
    RoutineTemplatesTable,
    RoutineTemplateBlocksTable,
    RecurrenceRulesTable,
    RecurrenceExceptionsTable,
    DailyReviewsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(routineTemplatesTable);
        await m.createTable(routineTemplateBlocksTable);
      }
      if (from < 3) {
        await m.createTable(recurrenceRulesTable);
        await m.createTable(recurrenceExceptionsTable);
        await m.createTable(dailyReviewsTable);
        await m.addColumn(activitiesTable, activitiesTable.recurrenceRuleId);
        await m.addColumn(
          activitiesTable,
          activitiesTable.isRecurrenceInstance,
        );
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dayweaver');
  }
}
