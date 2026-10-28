import 'package:drift/drift.dart';

@DataClassName('RoutineTemplateEntry')
class RoutineTemplatesTable extends Table {
  @override
  String get tableName => 'routine_templates';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoutineTemplateBlockEntry')
class RoutineTemplateBlocksTable extends Table {
  @override
  String get tableName => 'routine_template_blocks';

  TextColumn get id => text()();
  TextColumn get templateId => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();

  @override
  Set<Column> get primaryKey => {id};
}
