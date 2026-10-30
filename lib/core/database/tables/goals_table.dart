import 'package:drift/drift.dart';

@DataClassName('GoalEntry')
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';

  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()(); // GoalCategory name
  TextColumn get status => text().withDefault(
    const Constant('active'),
  )(); // active, paused, completed, archived
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))(); // low, medium, high
  RealColumn get targetValue => real()();
  RealColumn get currentValue => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withLength(min: 1, max: 50)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalMilestoneEntry')
class GoalMilestonesTable extends Table {
  @override
  String get tableName => 'goal_milestones';

  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(GoalsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalProgressUpdateEntry')
class GoalProgressUpdatesTable extends Table {
  @override
  String get tableName => 'goal_progress_updates';

  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(GoalsTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get changeAmount => real()();
  RealColumn get resultingValue => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ActivityGoalEntry')
class ActivityGoalsTable extends Table {
  @override
  String get tableName => 'activity_goals';

  TextColumn get activityId => text()();
  TextColumn get goalId =>
      text().references(GoalsTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {activityId, goalId};
}
