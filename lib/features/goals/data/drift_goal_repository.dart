import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../schedule/domain/activity_priority.dart';
import '../../schedule/domain/time_utils.dart';
import '../domain/goal.dart';
import '../domain/goal_category.dart';
import '../domain/goal_milestone.dart';
import '../domain/goal_progress_update.dart';
import '../domain/goal_status.dart';
import 'goal_repository.dart';

class DriftGoalRepository implements GoalRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DriftGoalRepository(this._db);

  Goal _mapGoalEntryToDomain(
    GoalEntry entry, {
    List<GoalMilestone> milestones = const [],
    List<String> linkedActivityIds = const [],
  }) {
    return Goal(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      category: GoalCategory.fromString(entry.category),
      status: GoalStatus.fromString(entry.status),
      priority: ActivityPriority.fromString(entry.priority),
      targetValue: entry.targetValue,
      currentValue: entry.currentValue,
      unit: entry.unit,
      startDate: entry.startDate,
      targetDate: entry.targetDate,
      notes: entry.notes,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      milestones: milestones,
      linkedActivityIds: linkedActivityIds,
    );
  }

  GoalsTableCompanion _mapDomainToCompanion(Goal goal) {
    return GoalsTableCompanion(
      id: Value(goal.id),
      title: Value(goal.title),
      description: Value(goal.description),
      category: Value(goal.category.name),
      status: Value(goal.status.name),
      priority: Value(goal.priority.name),
      targetValue: Value(goal.targetValue),
      currentValue: Value(goal.currentValue),
      unit: Value(goal.unit),
      startDate: Value(TimeUtils.normalizeDate(goal.startDate)),
      targetDate: Value(
        goal.targetDate != null
            ? TimeUtils.normalizeDate(goal.targetDate!)
            : null,
      ),
      notes: Value(goal.notes),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }

  GoalMilestone _mapMilestoneEntryToDomain(GoalMilestoneEntry entry) {
    return GoalMilestone(
      id: entry.id,
      goalId: entry.goalId,
      title: entry.title,
      description: entry.description,
      targetDate: entry.targetDate,
      orderIndex: entry.orderIndex,
      isCompleted: entry.isCompleted,
      completedAt: entry.completedAt,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  GoalMilestonesTableCompanion _mapMilestoneDomainToCompanion(
    GoalMilestone milestone,
  ) {
    return GoalMilestonesTableCompanion(
      id: Value(milestone.id),
      goalId: Value(milestone.goalId),
      title: Value(milestone.title),
      description: Value(milestone.description),
      targetDate: Value(
        milestone.targetDate != null
            ? TimeUtils.normalizeDate(milestone.targetDate!)
            : null,
      ),
      orderIndex: Value(milestone.orderIndex),
      isCompleted: Value(milestone.isCompleted),
      completedAt: Value(milestone.completedAt),
      createdAt: Value(milestone.createdAt),
      updatedAt: Value(milestone.updatedAt),
    );
  }

  GoalProgressUpdate _mapProgressUpdateEntryToDomain(
    GoalProgressUpdateEntry entry,
  ) {
    return GoalProgressUpdate(
      id: entry.id,
      goalId: entry.goalId,
      changeAmount: entry.changeAmount,
      resultingValue: entry.resultingValue,
      note: entry.note,
      createdAt: entry.createdAt,
    );
  }

  @override
  Stream<List<Goal>> watchGoals({GoalStatus? filterStatus}) {
    SimpleSelectStatement<$GoalsTableTable, GoalEntry> query = _db.select(
      _db.goalsTable,
    );
    if (filterStatus != null) {
      query = query..where((tbl) => tbl.status.equals(filterStatus.name));
    }
    query = query..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    return query.watch().asyncMap((List<GoalEntry> entries) async {
      final List<Goal> goals = [];
      for (final GoalEntry entry in entries) {
        final List<GoalMilestone> milestones = await getMilestones(entry.id);
        final List<String> linkedIds = await getLinkedActivityIdsForGoal(
          entry.id,
        );
        goals.add(
          _mapGoalEntryToDomain(
            entry,
            milestones: milestones,
            linkedActivityIds: linkedIds,
          ),
        );
      }
      return goals;
    });
  }

  @override
  Future<List<Goal>> getGoals({GoalStatus? filterStatus}) async {
    SimpleSelectStatement<$GoalsTableTable, GoalEntry> query = _db.select(
      _db.goalsTable,
    );
    if (filterStatus != null) {
      query = query..where((tbl) => tbl.status.equals(filterStatus.name));
    }
    query = query..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final List<GoalEntry> entries = await query.get();
    final List<Goal> goals = [];
    for (final GoalEntry entry in entries) {
      final List<GoalMilestone> milestones = await getMilestones(entry.id);
      final List<String> linkedIds = await getLinkedActivityIdsForGoal(
        entry.id,
      );
      goals.add(
        _mapGoalEntryToDomain(
          entry,
          milestones: milestones,
          linkedActivityIds: linkedIds,
        ),
      );
    }
    return goals;
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    final query = _db.select(_db.goalsTable)..where((tbl) => tbl.id.equals(id));
    final GoalEntry? entry = await query.getSingleOrNull();
    if (entry == null) return null;

    final List<GoalMilestone> milestones = await getMilestones(id);
    final List<String> linkedIds = await getLinkedActivityIdsForGoal(id);
    return _mapGoalEntryToDomain(
      entry,
      milestones: milestones,
      linkedActivityIds: linkedIds,
    );
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    await _db
        .into(_db.goalsTable)
        .insertOnConflictUpdate(_mapDomainToCompanion(goal));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.activityGoalsTable,
      )..where((tbl) => tbl.goalId.equals(id))).go();
      await (_db.delete(
        _db.goalProgressUpdatesTable,
      )..where((tbl) => tbl.goalId.equals(id))).go();
      await (_db.delete(
        _db.goalMilestonesTable,
      )..where((tbl) => tbl.goalId.equals(id))).go();
      await (_db.delete(
        _db.goalsTable,
      )..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  @override
  Future<void> updateGoalStatus(String id, GoalStatus status) async {
    await (_db.update(_db.goalsTable)..where((tbl) => tbl.id.equals(id))).write(
      GoalsTableCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> recordProgressUpdate({
    required String goalId,
    required double changeAmount,
    required bool isIncremental,
    String? note,
  }) async {
    await _db.transaction(() async {
      final Goal? goal = await getGoalById(goalId);
      if (goal == null) {
        throw Exception('Goal with ID "$goalId" not found.');
      }

      final double current = goal.currentValue;
      final double newValue = isIncremental
          ? (current + changeAmount).clamp(0.0, double.infinity)
          : changeAmount.clamp(0.0, double.infinity);
      final double delta = isIncremental ? changeAmount : (newValue - current);

      final String updateId = _uuid.v4();
      await _db
          .into(_db.goalProgressUpdatesTable)
          .insert(
            GoalProgressUpdatesTableCompanion(
              id: Value(updateId),
              goalId: Value(goalId),
              changeAmount: Value(delta),
              resultingValue: Value(newValue),
              note: Value(note),
              createdAt: Value(DateTime.now()),
            ),
          );

      final bool reached = newValue >= goal.targetValue;
      await (_db.update(
        _db.goalsTable,
      )..where((tbl) => tbl.id.equals(goalId))).write(
        GoalsTableCompanion(
          currentValue: Value(newValue),
          status: reached ? const Value('completed') : Value(goal.status.name),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Stream<List<GoalMilestone>> watchMilestones(String goalId) {
    final query = _db.select(_db.goalMilestonesTable)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.orderIndex),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);

    return query.watch().map(
      (List<GoalMilestoneEntry> entries) =>
          entries.map(_mapMilestoneEntryToDomain).toList(),
    );
  }

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async {
    final query = _db.select(_db.goalMilestonesTable)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.orderIndex),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);

    final List<GoalMilestoneEntry> entries = await query.get();
    return entries.map(_mapMilestoneEntryToDomain).toList();
  }

  @override
  Future<void> saveMilestone(GoalMilestone milestone) async {
    await _db
        .into(_db.goalMilestonesTable)
        .insertOnConflictUpdate(_mapMilestoneDomainToCompanion(milestone));
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    await (_db.delete(
      _db.goalMilestonesTable,
    )..where((tbl) => tbl.id.equals(milestoneId))).go();
  }

  @override
  Future<void> toggleMilestone(String milestoneId, bool isCompleted) async {
    await (_db.update(
      _db.goalMilestonesTable,
    )..where((tbl) => tbl.id.equals(milestoneId))).write(
      GoalMilestonesTableCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<List<GoalProgressUpdate>> watchProgressUpdates(String goalId) {
    final query = _db.select(_db.goalProgressUpdatesTable)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    return query.watch().map(
      (List<GoalProgressUpdateEntry> entries) =>
          entries.map(_mapProgressUpdateEntryToDomain).toList(),
    );
  }

  @override
  Future<List<GoalProgressUpdate>> getProgressUpdates(String goalId) async {
    final query = _db.select(_db.goalProgressUpdatesTable)
      ..where((tbl) => tbl.goalId.equals(goalId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final List<GoalProgressUpdateEntry> entries = await query.get();
    return entries.map(_mapProgressUpdateEntryToDomain).toList();
  }

  @override
  Future<void> linkActivityToGoal(String activityId, String goalId) async {
    await _db
        .into(_db.activityGoalsTable)
        .insertOnConflictUpdate(
          ActivityGoalsTableCompanion(
            activityId: Value(activityId),
            goalId: Value(goalId),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> unlinkActivityFromGoal(String activityId, String goalId) async {
    await (_db.delete(_db.activityGoalsTable)..where(
          (tbl) =>
              tbl.activityId.equals(activityId) & tbl.goalId.equals(goalId),
        ))
        .go();
  }

  @override
  Future<List<String>> getLinkedGoalIdsForActivity(String activityId) async {
    final query = _db.select(_db.activityGoalsTable)
      ..where((tbl) => tbl.activityId.equals(activityId));
    final entries = await query.get();
    return entries.map((e) => e.goalId).toList();
  }

  @override
  Future<List<String>> getLinkedActivityIdsForGoal(String goalId) async {
    final query = _db.select(_db.activityGoalsTable)
      ..where((tbl) => tbl.goalId.equals(goalId));
    final entries = await query.get();
    return entries.map((e) => e.activityId).toList();
  }

  @override
  Future<List<Goal>> getLinkedGoalsForActivity(String activityId) async {
    final List<String> goalIds = await getLinkedGoalIdsForActivity(activityId);
    final List<Goal> result = [];
    for (final String id in goalIds) {
      final Goal? g = await getGoalById(id);
      if (g != null) result.add(g);
    }
    return result;
  }

  @override
  Stream<List<Goal>> watchGoalsForActivity(String activityId) {
    final query = _db.select(_db.activityGoalsTable)
      ..where((tbl) => tbl.activityId.equals(activityId));
    return query.watch().asyncMap((rows) async {
      final List<Goal> result = [];
      for (final row in rows) {
        final Goal? g = await getGoalById(row.goalId);
        if (g != null) result.add(g);
      }
      return result;
    });
  }

  @override
  Future<int> getActiveGoalsCount() async {
    final countExp = _db.goalsTable.id.count();
    final query = _db.selectOnly(_db.goalsTable)
      ..addColumns([countExp])
      ..where(_db.goalsTable.status.equals(GoalStatus.active.name));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  @override
  Future<int> getCompletedGoalsCountForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final normStart = TimeUtils.normalizeDate(start);
    final normEnd = TimeUtils.normalizeDate(end);

    final countExp = _db.goalsTable.id.count();
    final query = _db.selectOnly(_db.goalsTable)
      ..addColumns([countExp])
      ..where(
        _db.goalsTable.status.equals(GoalStatus.completed.name) &
            _db.goalsTable.updatedAt.isBiggerOrEqualValue(normStart) &
            _db.goalsTable.updatedAt.isSmallerOrEqualValue(normEnd),
      );
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  @override
  Future<List<Goal>> getGoalsApproachingDeadline(DateTime deadlineLimit) async {
    final now = TimeUtils.normalizeDate(DateTime.now());
    final limit = TimeUtils.normalizeDate(deadlineLimit);

    final query = _db.select(_db.goalsTable)
      ..where(
        (tbl) =>
            tbl.status.equals(GoalStatus.active.name) &
            tbl.targetDate.isNotNull() &
            tbl.targetDate.isBiggerOrEqualValue(now) &
            tbl.targetDate.isSmallerOrEqualValue(limit),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.targetDate)]);

    final entries = await query.get();
    final List<Goal> result = [];
    for (final entry in entries) {
      result.add(await getGoalById(entry.id) ?? _mapGoalEntryToDomain(entry));
    }
    return result;
  }

  @override
  Future<int> getProgressUpdatesCountForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final normStart = TimeUtils.normalizeDate(start);
    final normEnd = TimeUtils.normalizeDate(end);

    final countExp = _db.goalProgressUpdatesTable.id.count();
    final query = _db.selectOnly(_db.goalProgressUpdatesTable)
      ..addColumns([countExp])
      ..where(
        _db.goalProgressUpdatesTable.createdAt.isBiggerOrEqualValue(normStart) &
            _db.goalProgressUpdatesTable.createdAt.isSmallerOrEqualValue(
              normEnd,
            ),
      );
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }
}
