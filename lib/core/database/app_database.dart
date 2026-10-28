import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/activities_table.dart';
import 'tables/routine_templates_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [ActivitiesTable, RoutineTemplatesTable, RoutineTemplateBlocksTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.createTable(routineTemplatesTable);
        await m.createTable(routineTemplateBlocksTable);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dayweaver');
  }
}
