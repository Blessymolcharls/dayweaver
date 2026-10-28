import 'package:drift/drift.dart';

@DataClassName('ActivityEntry')
class ActivitiesTable extends Table {
  @override
  String get tableName => 'activities';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  IntColumn get reminderOffset => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get recurrenceRuleId => text().nullable()();
  BoolColumn get isRecurrenceInstance =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
