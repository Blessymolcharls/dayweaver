import 'package:drift/drift.dart';

@DataClassName('DailyReviewEntry')
class DailyReviewsTable extends Table {
  @override
  String get tableName => 'daily_reviews';

  DateTimeColumn get date => dateTime()(); // normalized calendar date
  TextColumn get reflectionNotes => text().nullable()();
  IntColumn get completedTasksCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalTasksCount => integer().withDefault(const Constant(0))();
  IntColumn get completedMinutes => integer().withDefault(const Constant(0))();
  IntColumn get totalPlannedMinutes =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get reviewedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}
