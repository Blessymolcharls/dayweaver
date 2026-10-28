import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/batch_operation_result.dart';
import '../domain/conflict_strategy.dart';
import '../domain/routine_template.dart';
import '../domain/routine_template_block.dart';
import '../domain/time_utils.dart';
import 'activity_repository.dart';

class DriftActivityRepository implements ActivityRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

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

  RoutineTemplateBlock _mapBlockEntryToDomain(RoutineTemplateBlockEntry entry) {
    return RoutineTemplateBlock(
      id: entry.id,
      templateId: entry.templateId,
      title: entry.title,
      category: ActivityCategory.fromString(entry.category),
      startMinute: entry.startMinute,
      endMinute: entry.endMinute,
      notes: entry.notes,
      priority: ActivityPriority.fromString(entry.priority),
    );
  }

  RoutineTemplateBlocksTableCompanion _mapBlockDomainToCompanion(
    RoutineTemplateBlock block,
  ) {
    return RoutineTemplateBlocksTableCompanion(
      id: Value(block.id),
      templateId: Value(block.templateId),
      title: Value(block.title),
      category: Value(block.category.name),
      startMinute: Value(block.startMinute),
      endMinute: Value(block.endMinute),
      notes: Value(block.notes),
      priority: Value(block.priority.name),
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

  @override
  Future<Activity> duplicateActivity(
    String id, {
    DateTime? targetDate,
    int? targetStartMinute,
  }) async {
    final original = await getActivityById(id);
    if (original == null) {
      throw Exception('Activity with ID "$id" not found.');
    }

    final date = TimeUtils.normalizeDate(targetDate ?? original.date);
    final duration = original.durationMinutes;
    int start = targetStartMinute ?? original.startMinute;
    int end = (start + duration).clamp(0, TimeUtils.minutesPerDay);

    // If target date equals original date and targetStartMinute is not explicitly set,
    // find a free gap if the original span is occupied
    if (targetDate == null && targetStartMinute == null) {
      final existing = await getActivitiesForDate(date);
      final overlap = TimeUtils.checkOverlap(
        startMinute: start,
        endMinute: end,
        existingActivities: existing,
      );
      if (overlap.hasOverlap) {
        final gaps = TimeUtils.calculateUnscheduledGaps(existing);
        final fittingGap = gaps
            .where((g) => g.durationMinutes >= duration)
            .firstOrNull;
        if (fittingGap != null) {
          start = fittingGap.startMinute;
          end = start + duration;
        } else {
          // If no full gap fits, start at first free minute or end of day
          if (gaps.isNotEmpty) {
            start = gaps.first.startMinute;
            end = (start + duration).clamp(0, TimeUtils.minutesPerDay);
          }
        }
      }
    }

    final duplicate = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      date: date,
      startMinute: start,
      endMinute: end,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveActivity(duplicate);
    return duplicate;
  }

  @override
  Future<void> moveActivity(
    String id, {
    required DateTime newDate,
    required int newStartMinute,
    required int newEndMinute,
  }) async {
    final original = await getActivityById(id);
    if (original == null) {
      throw Exception('Activity with ID "$id" not found.');
    }

    final validationErr = TimeUtils.validateTimeRange(
      newStartMinute,
      newEndMinute,
    );
    if (validationErr != null) {
      throw Exception(validationErr);
    }

    final normalizedDate = TimeUtils.normalizeDate(newDate);
    final existingOnDate = await getActivitiesForDate(normalizedDate);

    final overlap = TimeUtils.checkOverlap(
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      existingActivities: existingOnDate,
      excludeActivityId: id,
    );

    if (overlap.hasOverlap) {
      throw Exception(
        'Cannot move: overlaps with "${overlap.conflictingTitle}".',
      );
    }

    final updated = original.copyWith(
      date: normalizedDate,
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      updatedAt: DateTime.now(),
    );

    await saveActivity(updated);
  }

  @override
  Future<Set<DateTime>> getDatesWithActivities(
    DateTime startRange,
    DateTime endRange,
  ) async {
    final start = TimeUtils.normalizeDate(startRange);
    final end = TimeUtils.normalizeDate(endRange);

    final query = _db.selectOnly(_db.activitiesTable, distinct: true)
      ..addColumns([_db.activitiesTable.date])
      ..where(
        _db.activitiesTable.date.isBiggerOrEqualValue(start) &
            _db.activitiesTable.date.isSmallerOrEqualValue(end),
      );

    final rows = await query.get();
    return rows
        .map((r) => r.read(_db.activitiesTable.date))
        .whereType<DateTime>()
        .map(TimeUtils.normalizeDate)
        .toSet();
  }

  // --- Routine Templates Implementation ---

  @override
  Stream<List<RoutineTemplate>> watchTemplates() {
    final templatesStream = (_db.select(
      _db.routineTemplatesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

    return templatesStream.asyncMap((templateEntries) async {
      final templates = <RoutineTemplate>[];
      for (final t in templateEntries) {
        final blocksQuery = _db.select(_db.routineTemplateBlocksTable)
          ..where((b) => b.templateId.equals(t.id))
          ..orderBy([(b) => OrderingTerm.asc(b.startMinute)]);
        final blockEntries = await blocksQuery.get();

        templates.add(
          RoutineTemplate(
            id: t.id,
            name: t.name,
            description: t.description,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
            blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
          ),
        );
      }
      return templates;
    });
  }

  @override
  Future<List<RoutineTemplate>> getTemplates() async {
    final templateEntries = await (_db.select(
      _db.routineTemplatesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

    final templates = <RoutineTemplate>[];
    for (final t in templateEntries) {
      final blocksQuery = _db.select(_db.routineTemplateBlocksTable)
        ..where((b) => b.templateId.equals(t.id))
        ..orderBy([(b) => OrderingTerm.asc(b.startMinute)]);
      final blockEntries = await blocksQuery.get();

      templates.add(
        RoutineTemplate(
          id: t.id,
          name: t.name,
          description: t.description,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
          blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
        ),
      );
    }
    return templates;
  }

  @override
  Future<RoutineTemplate?> getTemplateById(String id) async {
    final t = await (_db.select(
      _db.routineTemplatesTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    if (t == null) return null;

    final blockEntries =
        await (_db.select(_db.routineTemplateBlocksTable)
              ..where((b) => b.templateId.equals(id))
              ..orderBy([(b) => OrderingTerm.asc(b.startMinute)]))
            .get();

    return RoutineTemplate(
      id: t.id,
      name: t.name,
      description: t.description,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
    );
  }

  @override
  Future<void> saveTemplate(RoutineTemplate template) async {
    await _db.transaction(() async {
      await _db
          .into(_db.routineTemplatesTable)
          .insertOnConflictUpdate(
            RoutineTemplatesTableCompanion(
              id: Value(template.id),
              name: Value(template.name),
              description: Value(template.description),
              createdAt: Value(template.createdAt),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // Replace blocks
      await (_db.delete(
        _db.routineTemplateBlocksTable,
      )..where((b) => b.templateId.equals(template.id))).go();

      for (final block in template.blocks) {
        await _db
            .into(_db.routineTemplateBlocksTable)
            .insertOnConflictUpdate(_mapBlockDomainToCompanion(block));
      }
    });
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.routineTemplateBlocksTable,
      )..where((b) => b.templateId.equals(id))).go();
      await (_db.delete(
        _db.routineTemplatesTable,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> saveTemplateBlock(RoutineTemplateBlock block) async {
    await _db
        .into(_db.routineTemplateBlocksTable)
        .insertOnConflictUpdate(_mapBlockDomainToCompanion(block));
  }

  @override
  Future<void> deleteTemplateBlock(String blockId) async {
    await (_db.delete(
      _db.routineTemplateBlocksTable,
    )..where((b) => b.id.equals(blockId))).go();
  }

  @override
  Future<int> countTemplates() async {
    final countExp = _db.routineTemplatesTable.id.count();
    final query = _db.selectOnly(_db.routineTemplatesTable)
      ..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  // --- Batch Operations (Transactional) ---

  @override
  Future<BatchOperationResult> applyTemplateToDate({
    required String templateId,
    required DateTime date,
    required ConflictStrategy conflictStrategy,
  }) async {
    final normalizedDate = TimeUtils.normalizeDate(date);
    final template = await getTemplateById(templateId);
    if (template == null) {
      return BatchOperationResult.failure('Template not found.');
    }
    if (template.blocks.isEmpty) {
      return BatchOperationResult.success(addedCount: 0, skippedCount: 0);
    }

    return await _db
        .transaction(() async {
          final existing = await getActivitiesForDate(normalizedDate);

          if (conflictStrategy == ConflictStrategy.overwrite) {
            // Clear all existing activities on that date
            await (_db.delete(
              _db.activitiesTable,
            )..where((tbl) => tbl.date.equals(normalizedDate))).go();

            for (final block in template.blocks) {
              final act = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
              );
              await saveActivity(act);
            }

            return BatchOperationResult.success(
              addedCount: template.blocks.length,
              skippedCount: 0,
            );
          }

          if (conflictStrategy == ConflictStrategy.abortOnConflict) {
            // Verify every block has no conflict
            for (final block in template.blocks) {
              final overlap = TimeUtils.checkOverlap(
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                existingActivities: existing,
              );
              if (overlap.hasOverlap) {
                throw Exception(
                  'Cannot apply routine: "${block.title}" conflicts with "${overlap.conflictingTitle}".',
                );
              }
            }

            for (final block in template.blocks) {
              final act = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
              );
              await saveActivity(act);
            }

            return BatchOperationResult.success(
              addedCount: template.blocks.length,
              skippedCount: 0,
            );
          }

          // ConflictStrategy.skipConflicts
          int added = 0;
          int skipped = 0;
          final runningList = List<Activity>.from(existing);

          for (final block in template.blocks) {
            final overlap = TimeUtils.checkOverlap(
              startMinute: block.startMinute,
              endMinute: block.endMinute,
              existingActivities: runningList,
            );

            if (overlap.hasOverlap) {
              skipped++;
            } else {
              final act = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
              );
              await saveActivity(act);
              runningList.add(act);
              added++;
            }
          }

          return BatchOperationResult.success(
            addedCount: added,
            skippedCount: skipped,
          );
        })
        .catchError((e) {
          return BatchOperationResult.failure(
            e.toString().replaceAll('Exception: ', ''),
          );
        });
  }

  @override
  Future<BatchOperationResult> copySchedule({
    required DateTime fromDate,
    required DateTime toDate,
    required ConflictStrategy conflictStrategy,
  }) async {
    final normalizedFrom = TimeUtils.normalizeDate(fromDate);
    final normalizedTo = TimeUtils.normalizeDate(toDate);

    if (normalizedFrom.isAtSameMomentAs(normalizedTo)) {
      return BatchOperationResult.failure(
        'Source and destination dates cannot be the same.',
      );
    }

    final sourceActivities = await getActivitiesForDate(normalizedFrom);
    if (sourceActivities.isEmpty) {
      return BatchOperationResult.failure(
        'No activities found on the source date to copy.',
      );
    }

    return await _db
        .transaction(() async {
          final destActivities = await getActivitiesForDate(normalizedTo);

          if (conflictStrategy == ConflictStrategy.overwrite) {
            // Clear destination date activities
            await (_db.delete(
              _db.activitiesTable,
            )..where((tbl) => tbl.date.equals(normalizedTo))).go();

            for (final act in sourceActivities) {
              final copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(copy);
            }

            return BatchOperationResult.success(
              addedCount: sourceActivities.length,
              skippedCount: 0,
            );
          }

          if (conflictStrategy == ConflictStrategy.abortOnConflict) {
            for (final act in sourceActivities) {
              final overlap = TimeUtils.checkOverlap(
                startMinute: act.startMinute,
                endMinute: act.endMinute,
                existingActivities: destActivities,
              );
              if (overlap.hasOverlap) {
                throw Exception(
                  'Cannot copy schedule: "${act.title}" conflicts with "${overlap.conflictingTitle}".',
                );
              }
            }

            for (final act in sourceActivities) {
              final copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(copy);
            }

            return BatchOperationResult.success(
              addedCount: sourceActivities.length,
              skippedCount: 0,
            );
          }

          // ConflictStrategy.skipConflicts
          int added = 0;
          int skipped = 0;
          final runningList = List<Activity>.from(destActivities);

          for (final act in sourceActivities) {
            final overlap = TimeUtils.checkOverlap(
              startMinute: act.startMinute,
              endMinute: act.endMinute,
              existingActivities: runningList,
            );

            if (overlap.hasOverlap) {
              skipped++;
            } else {
              final copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(copy);
              runningList.add(copy);
              added++;
            }
          }

          return BatchOperationResult.success(
            addedCount: added,
            skippedCount: skipped,
          );
        })
        .catchError((e) {
          return BatchOperationResult.failure(
            e.toString().replaceAll('Exception: ', ''),
          );
        });
  }
}
