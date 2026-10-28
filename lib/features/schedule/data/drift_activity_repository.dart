import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/time_utils.dart';
import 'activity_repository.dart';

class DriftActivityRepository implements ActivityRepository {
  final AppDatabase _db;

  DriftActivityRepository(this._db);

  Activity _mapEntryToDomain(ActivityEntry entry) {
    return Activity(
      id: entry.id,
      title: entry.title,
      category: ActivityCategory.fromString(entry.category),
      date: entry.date,
      startMinute: entry.startMinute,
      endMinute: entry.endMinute,
      notes: entry.notes,
      isCompleted: entry.isCompleted,
      priority: ActivityPriority.fromString(entry.priority),
      reminderOffsetMinutes: entry.reminderOffset,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  ActivitiesTableCompanion _mapDomainToCompanion(Activity activity) {
    return ActivitiesTableCompanion(
      id: Value(activity.id),
      title: Value(activity.title),
      category: Value(activity.category.name),
      date: Value(TimeUtils.normalizeDate(activity.date)),
      startMinute: Value(activity.startMinute),
      endMinute: Value(activity.endMinute),
      notes: Value(activity.notes),
      isCompleted: Value(activity.isCompleted),
      priority: Value(activity.priority.name),
      reminderOffset: Value(activity.reminderOffsetMinutes),
      createdAt: Value(activity.createdAt),
      updatedAt: Value(activity.updatedAt),
    );
  }

  @override
  Stream<List<Activity>> watchActivitiesForDate(DateTime date) {
    final normalized = TimeUtils.normalizeDate(date);
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.date.equals(normalized))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);

    return query.watch().map(
      (entries) => entries.map(_mapEntryToDomain).toList(),
    );
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final normalized = TimeUtils.normalizeDate(date);
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.date.equals(normalized))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);

    final entries = await query.get();
    return entries.map(_mapEntryToDomain).toList();
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.id.equals(id));
    final entry = await query.getSingleOrNull();
    return entry != null ? _mapEntryToDomain(entry) : null;
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    final companion = _mapDomainToCompanion(activity);
    await _db.into(_db.activitiesTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteActivity(String id) async {
    await (_db.delete(
      _db.activitiesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await (_db.update(
      _db.activitiesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      ActivitiesTableCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<int> countActivities() async {
    final countExp = _db.activitiesTable.id.count();
    final query = _db.selectOnly(_db.activitiesTable)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }
}
