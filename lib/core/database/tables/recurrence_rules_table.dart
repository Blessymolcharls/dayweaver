import 'package:drift/drift.dart';

@DataClassName('RecurrenceRuleEntry')
class RecurrenceRulesTable extends Table {
  @override
  String get tableName => 'recurrence_rules';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
  TextColumn get recurrenceType =>
      text()(); // 'daily', 'weekdays', 'custom_days'
  TextColumn get daysOfWeek => text()(); // comma-separated e.g. "1,2,3,4,5"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  IntColumn get reminderOffset => integer().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurrenceExceptionEntry')
class RecurrenceExceptionsTable extends Table {
  @override
  String get tableName => 'recurrence_exceptions';

  TextColumn get id => text()();
  TextColumn get ruleId => text().references(
    RecurrenceRulesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get exceptionDate => dateTime()();
  TextColumn get reason => text().nullable()(); // 'skipped', 'modified'

  @override
  Set<Column> get primaryKey => {id};
}
