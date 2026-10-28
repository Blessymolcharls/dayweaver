import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/batch_operation_result.dart';
import '../domain/conflict_strategy.dart';
import '../domain/daily_review.dart';
import '../domain/recurrence_rule.dart';
import '../domain/routine_template.dart';
import '../domain/routine_template_block.dart';
import '../domain/time_utils.dart';
import 'activity_repository.dart';

class DriftActivityRepository implements ActivityRepository {
  final AppDatabase _db;
  final NotificationService? _notificationService;
  final Uuid _uuid = const Uuid();

  DriftActivityRepository(this._db, [this._notificationService]);

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
      recurrenceRuleId: entry.recurrenceRuleId,
      isRecurrenceInstance: entry.isRecurrenceInstance,
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
      recurrenceRuleId: Value(activity.recurrenceRuleId),
      isRecurrenceInstance: Value(activity.isRecurrenceInstance),
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

  RecurrenceRule _mapRecurrenceEntryToDomain(RecurrenceRuleEntry entry) {
    final List<int> days = entry.daysOfWeek
        .split(',')
        .map((String s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    return RecurrenceRule(
      id: entry.id,
      title: entry.title,
      category: ActivityCategory.fromString(entry.category),
      startMinute: entry.startMinute,
      endMinute: entry.endMinute,
      recurrenceType: RecurrenceType.fromString(entry.recurrenceType),
      daysOfWeek: days,
      startDate: entry.startDate,
      endDate: entry.endDate,
      notes: entry.notes,
      priority: ActivityPriority.fromString(entry.priority),
      reminderOffsetMinutes: entry.reminderOffset,
      isEnabled: entry.isEnabled,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  RecurrenceRulesTableCompanion _mapRecurrenceDomainToCompanion(
    RecurrenceRule rule,
  ) {
    return RecurrenceRulesTableCompanion(
      id: Value(rule.id),
      title: Value(rule.title),
      category: Value(rule.category.name),
      startMinute: Value(rule.startMinute),
      endMinute: Value(rule.endMinute),
      recurrenceType: Value(rule.recurrenceType.name),
      daysOfWeek: Value(rule.daysOfWeek.join(',')),
      startDate: Value(TimeUtils.normalizeDate(rule.startDate)),
      endDate: Value(
        rule.endDate != null ? TimeUtils.normalizeDate(rule.endDate!) : null,
      ),
      notes: Value(rule.notes),
      priority: Value(rule.priority.name),
      reminderOffset: Value(rule.reminderOffsetMinutes),
      isEnabled: Value(rule.isEnabled),
      createdAt: Value(rule.createdAt),
      updatedAt: Value(rule.updatedAt),
    );
  }

  DailyReview _mapReviewEntryToDomain(DailyReviewEntry entry) {
    return DailyReview(
      date: entry.date,
      reflectionNotes: entry.reflectionNotes,
      completedTasksCount: entry.completedTasksCount,
      totalTasksCount: entry.totalTasksCount,
      completedMinutes: entry.completedMinutes,
      totalPlannedMinutes: entry.totalPlannedMinutes,
      reviewedAt: entry.reviewedAt,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  DailyReviewsTableCompanion _mapReviewDomainToCompanion(DailyReview review) {
    return DailyReviewsTableCompanion(
      date: Value(TimeUtils.normalizeDate(review.date)),
      reflectionNotes: Value(review.reflectionNotes),
      completedTasksCount: Value(review.completedTasksCount),
      totalTasksCount: Value(review.totalTasksCount),
      completedMinutes: Value(review.completedMinutes),
      totalPlannedMinutes: Value(review.totalPlannedMinutes),
      reviewedAt: Value(review.reviewedAt),
      createdAt: Value(review.createdAt),
      updatedAt: Value(review.updatedAt),
    );
  }

  @override
  Stream<List<Activity>> watchActivitiesForDate(DateTime date) {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.date.equals(normalized))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);

    return query.watch().map(
      (List<ActivityEntry> entries) => entries.map(_mapEntryToDomain).toList(),
    );
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.date.equals(normalized))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);

    final List<ActivityEntry> entries = await query.get();
    return entries.map(_mapEntryToDomain).toList();
  }

  @override
  Future<List<Activity>> getActivitiesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final DateTime normalizedStart = TimeUtils.normalizeDate(startDate);
    final DateTime normalizedEnd = TimeUtils.normalizeDate(endDate);

    final query = _db.select(_db.activitiesTable)
      ..where(
        (tbl) =>
            tbl.date.isBiggerOrEqualValue(normalizedStart) &
            tbl.date.isSmallerOrEqualValue(normalizedEnd),
      )
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.date),
        (tbl) => OrderingTerm.asc(tbl.startMinute),
      ]);

    final List<ActivityEntry> entries = await query.get();
    return entries.map(_mapEntryToDomain).toList();
  }

  @override
  Stream<List<Activity>> watchActivitiesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final DateTime normalizedStart = TimeUtils.normalizeDate(startDate);
    final DateTime normalizedEnd = TimeUtils.normalizeDate(endDate);

    final query = _db.select(_db.activitiesTable)
      ..where(
        (tbl) =>
            tbl.date.isBiggerOrEqualValue(normalizedStart) &
            tbl.date.isSmallerOrEqualValue(normalizedEnd),
      )
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.date),
        (tbl) => OrderingTerm.asc(tbl.startMinute),
      ]);

    return query.watch().map(
      (List<ActivityEntry> entries) => entries.map(_mapEntryToDomain).toList(),
    );
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    final query = _db.select(_db.activitiesTable)
      ..where((tbl) => tbl.id.equals(id));
    final ActivityEntry? entry = await query.getSingleOrNull();
    return entry != null ? _mapEntryToDomain(entry) : null;
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    final ActivitiesTableCompanion companion = _mapDomainToCompanion(activity);
    await _db.into(_db.activitiesTable).insertOnConflictUpdate(companion);

    // Coordinate with notification service safely
    if (_notificationService != null) {
      try {
        if (activity.reminderOffsetMinutes != null && !activity.isCompleted) {
          await _notificationService.scheduleActivityReminder(activity);
        } else {
          await _notificationService.cancelActivityReminder(activity.id);
        }
      } catch (_) {
        // Notification failure never corrupts database
      }
    }
  }

  @override
  Future<void> deleteActivity(String id) async {
    final Activity? activity = await getActivityById(id);
    if (activity != null && activity.recurrenceRuleId != null) {
      // Record exception so this single occurrence is not regenerated
      await addRecurrenceException(activity.recurrenceRuleId!, activity.date);
    }

    await (_db.delete(
      _db.activitiesTable,
    )..where((tbl) => tbl.id.equals(id))).go();

    if (_notificationService != null) {
      try {
        await _notificationService.cancelActivityReminder(id);
      } catch (_) {}
    }
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

    if (_notificationService != null) {
      try {
        if (isCompleted) {
          await _notificationService.cancelActivityReminder(id);
        } else {
          final Activity? act = await getActivityById(id);
          if (act != null && act.reminderOffsetMinutes != null) {
            await _notificationService.scheduleActivityReminder(act);
          }
        }
      } catch (_) {}
    }
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
        final fittingGap =
            gaps.where((g) => g.durationMinutes >= duration).firstOrNull;
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
      recurrenceRuleId: null,
      isRecurrenceInstance: false,
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
    final Activity? current = await getActivityById(id);
    if (current == null) {
      throw Exception('Activity with id $id not found');
    }

    final String? rangeError = TimeUtils.validateTimeRange(
      newStartMinute,
      newEndMinute,
    );
    if (rangeError != null) {
      throw Exception(rangeError);
    }

    final List<Activity> existing = await getActivitiesForDate(newDate);
    final overlap = TimeUtils.checkOverlap(
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      existingActivities: existing,
      excludeActivityId: current.date == newDate ? current.id : null,
    );

    if (overlap.hasOverlap) {
      throw Exception(
        'Cannot move: conflicts with "${overlap.conflictingTitle}".',
      );
    }

    final Activity moved = current.copyWith(
      date: newDate,
      startMinute: newStartMinute,
      endMinute: newEndMinute,
      updatedAt: DateTime.now(),
    );

    await saveActivity(moved);
  }

  @override
  Future<Set<DateTime>> getDatesWithActivities(
    DateTime startRange,
    DateTime endRange,
  ) async {
    final DateTime normalizedStart = TimeUtils.normalizeDate(startRange);
    final DateTime normalizedEnd = TimeUtils.normalizeDate(endRange);

    final query = _db.selectOnly(_db.activitiesTable, distinct: true)
      ..addColumns([_db.activitiesTable.date])
      ..where(
        _db.activitiesTable.date.isBiggerOrEqualValue(normalizedStart) &
            _db.activitiesTable.date.isSmallerOrEqualValue(normalizedEnd),
      );

    final results = await query
        .map((row) => row.read(_db.activitiesTable.date)!)
        .get();

    return results.map(TimeUtils.normalizeDate).toSet();
  }

  // Routine Templates
  @override
  Stream<List<RoutineTemplate>> watchTemplates() {
    return _db.select(_db.routineTemplatesTable).watch().asyncMap((
      List<RoutineTemplateEntry> templateEntries,
    ) async {
      final List<RoutineTemplate> templates = [];
      for (final RoutineTemplateEntry entry in templateEntries) {
        final blocksQuery = _db.select(_db.routineTemplateBlocksTable)
          ..where((tbl) => tbl.templateId.equals(entry.id))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);
        final blockEntries = await blocksQuery.get();
        templates.add(
          RoutineTemplate(
            id: entry.id,
            name: entry.name,
            description: entry.description,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
          ),
        );
      }
      return templates;
    });
  }

  @override
  Future<List<RoutineTemplate>> getTemplates() async {
    final templateEntries = await _db.select(_db.routineTemplatesTable).get();
    final List<RoutineTemplate> templates = [];
    for (final RoutineTemplateEntry entry in templateEntries) {
      final blocksQuery = _db.select(_db.routineTemplateBlocksTable)
        ..where((tbl) => tbl.templateId.equals(entry.id))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);
      final blockEntries = await blocksQuery.get();
      templates.add(
        RoutineTemplate(
          id: entry.id,
          name: entry.name,
          description: entry.description,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
          blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
        ),
      );
    }
    return templates;
  }

  @override
  Future<RoutineTemplate?> getTemplateById(String id) async {
    final query = _db.select(_db.routineTemplatesTable)
      ..where((tbl) => tbl.id.equals(id));
    final entry = await query.getSingleOrNull();
    if (entry == null) return null;

    final blocksQuery = _db.select(_db.routineTemplateBlocksTable)
      ..where((tbl) => tbl.templateId.equals(id))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.startMinute)]);
    final blockEntries = await blocksQuery.get();

    return RoutineTemplate(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      blocks: blockEntries.map(_mapBlockEntryToDomain).toList(),
    );
  }

  @override
  Future<void> saveTemplate(RoutineTemplate template) async {
    await _db.transaction(() async {
      await _db.into(_db.routineTemplatesTable).insertOnConflictUpdate(
            RoutineTemplatesTableCompanion(
              id: Value(template.id),
              name: Value(template.name),
              description: Value(template.description),
              createdAt: Value(template.createdAt),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // Replace blocks
      await (_db.delete(_db.routineTemplateBlocksTable)
            ..where((tbl) => tbl.templateId.equals(template.id)))
          .go();

      for (final RoutineTemplateBlock block in template.blocks) {
        await _db
            .into(_db.routineTemplateBlocksTable)
            .insertOnConflictUpdate(_mapBlockDomainToCompanion(block));
      }
    });
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await (_db.delete(
      _db.routineTemplatesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
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
    )..where((tbl) => tbl.id.equals(blockId))).go();
  }

  @override
  Future<int> countTemplates() async {
    final countExp = _db.routineTemplatesTable.id.count();
    final query = _db.selectOnly(_db.routineTemplatesTable)
      ..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  @override
  Future<BatchOperationResult> applyTemplateToDate({
    required String templateId,
    required DateTime date,
    required ConflictStrategy conflictStrategy,
  }) async {
    final RoutineTemplate? template = await getTemplateById(templateId);
    if (template == null) {
      return BatchOperationResult.failure('Template not found.');
    }

    if (template.blocks.isEmpty) {
      return BatchOperationResult.failure('Template has no activity blocks.');
    }

    final DateTime normalizedDate = TimeUtils.normalizeDate(date);

    return _db
        .transaction(() async {
          final List<Activity> existingActivities = await getActivitiesForDate(
            normalizedDate,
          );

          if (conflictStrategy == ConflictStrategy.overwrite) {
            for (final Activity act in existingActivities) {
              await deleteActivity(act.id);
            }

            for (final RoutineTemplateBlock block in template.blocks) {
              final Activity newAct = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(newAct);
            }

            return BatchOperationResult.success(
              addedCount: template.blocks.length,
              skippedCount: 0,
            );
          }

          if (conflictStrategy == ConflictStrategy.abortOnConflict) {
            for (final RoutineTemplateBlock block in template.blocks) {
              final overlap = TimeUtils.checkOverlap(
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                existingActivities: existingActivities,
              );
              if (overlap.hasOverlap) {
                throw Exception(
                  'Cannot apply routine: "${block.title}" conflicts with "${overlap.conflictingTitle}".',
                );
              }
            }

            for (final RoutineTemplateBlock block in template.blocks) {
              final Activity newAct = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(newAct);
            }

            return BatchOperationResult.success(
              addedCount: template.blocks.length,
              skippedCount: 0,
            );
          }

          // ConflictStrategy.skipConflicts
          int added = 0;
          int skipped = 0;
          final List<Activity> runningList = List<Activity>.from(
            existingActivities,
          );

          for (final RoutineTemplateBlock block in template.blocks) {
            final overlap = TimeUtils.checkOverlap(
              startMinute: block.startMinute,
              endMinute: block.endMinute,
              existingActivities: runningList,
            );

            if (overlap.hasOverlap) {
              skipped++;
            } else {
              final Activity newAct = Activity(
                id: _uuid.v4(),
                title: block.title,
                category: block.category,
                date: normalizedDate,
                startMinute: block.startMinute,
                endMinute: block.endMinute,
                notes: block.notes,
                priority: block.priority,
                isCompleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await saveActivity(newAct);
              runningList.add(newAct);
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
    final DateTime normalizedFrom = TimeUtils.normalizeDate(fromDate);
    final DateTime normalizedTo = TimeUtils.normalizeDate(toDate);

    if (normalizedFrom == normalizedTo) {
      return BatchOperationResult.failure(
        'Source and destination dates cannot be the same.',
      );
    }

    final List<Activity> sourceActivities = await getActivitiesForDate(
      normalizedFrom,
    );
    if (sourceActivities.isEmpty) {
      return BatchOperationResult.failure(
        'No activities found on the source date to copy.',
      );
    }

    return _db
        .transaction(() async {
          final List<Activity> destActivities = await getActivitiesForDate(
            normalizedTo,
          );

          if (conflictStrategy == ConflictStrategy.overwrite) {
            for (final Activity act in destActivities) {
              await deleteActivity(act.id);
            }

            for (final Activity act in sourceActivities) {
              final Activity copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                recurrenceRuleId: null,
                isRecurrenceInstance: false,
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
            for (final Activity act in sourceActivities) {
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

            for (final Activity act in sourceActivities) {
              final Activity copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                recurrenceRuleId: null,
                isRecurrenceInstance: false,
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
          final List<Activity> runningList = List<Activity>.from(
            destActivities,
          );

          for (final Activity act in sourceActivities) {
            final overlap = TimeUtils.checkOverlap(
              startMinute: act.startMinute,
              endMinute: act.endMinute,
              existingActivities: runningList,
            );

            if (overlap.hasOverlap) {
              skipped++;
            } else {
              final Activity copy = act.copyWith(
                id: _uuid.v4(),
                date: normalizedTo,
                isCompleted: false,
                recurrenceRuleId: null,
                isRecurrenceInstance: false,
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

  // Recurrence Rules
  @override
  Stream<List<RecurrenceRule>> watchRecurrenceRules() {
    return _db
        .select(_db.recurrenceRulesTable)
        .watch()
        .map(
          (List<RecurrenceRuleEntry> entries) =>
              entries.map(_mapRecurrenceEntryToDomain).toList(),
        );
  }

  @override
  Future<List<RecurrenceRule>> getRecurrenceRules() async {
    final entries = await _db.select(_db.recurrenceRulesTable).get();
    return entries.map(_mapRecurrenceEntryToDomain).toList();
  }

  @override
  Future<RecurrenceRule?> getRecurrenceRuleById(String id) async {
    final query = _db.select(_db.recurrenceRulesTable)
      ..where((tbl) => tbl.id.equals(id));
    final entry = await query.getSingleOrNull();
    return entry != null ? _mapRecurrenceEntryToDomain(entry) : null;
  }

  @override
  Future<void> saveRecurrenceRule(RecurrenceRule rule) async {
    await _db
        .into(_db.recurrenceRulesTable)
        .insertOnConflictUpdate(_mapRecurrenceDomainToCompanion(rule));
  }

  @override
  Future<void> deleteRecurrenceRule(String id) async {
    await (_db.delete(
      _db.recurrenceRulesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> toggleRecurrenceRuleEnabled(String id, bool isEnabled) async {
    await (_db.update(
      _db.recurrenceRulesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      RecurrenceRulesTableCompanion(
        isEnabled: Value(isEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> addRecurrenceException(String ruleId, DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    final String exceptionId =
        'exc_${ruleId}_${normalized.year}_${normalized.month}_${normalized.day}';

    await _db
        .into(_db.recurrenceExceptionsTable)
        .insertOnConflictUpdate(
          RecurrenceExceptionsTableCompanion(
            id: Value(exceptionId),
            ruleId: Value(ruleId),
            exceptionDate: Value(normalized),
            reason: const Value('skipped'),
          ),
        );
  }

  @override
  Future<int> generateRecurringActivitiesForDate(DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    final List<RecurrenceRule> allRules = await getRecurrenceRules();
    final List<RecurrenceRule> matchingRules = allRules
        .where((RecurrenceRule r) => r.matchesDate(normalized))
        .toList();

    if (matchingRules.isEmpty) return 0;

    // Fetch exceptions for this date
    final exceptionEntries = await (_db.select(
      _db.recurrenceExceptionsTable,
    )..where((tbl) => tbl.exceptionDate.equals(normalized))).get();
    final Set<String> exceptionRuleIds = exceptionEntries
        .map((e) => e.ruleId)
        .toSet();

    final List<Activity> existing = await getActivitiesForDate(normalized);
    final Set<String> existingIds = existing.map((a) => a.id).toSet();

    int generatedCount = 0;
    for (final RecurrenceRule rule in matchingRules) {
      if (exceptionRuleIds.contains(rule.id)) {
        continue;
      }

      // Stable idempotent identifier for this occurrence
      final String stableId =
          'rec_${rule.id}_${normalized.year}_${normalized.month}_${normalized.day}';

      if (existingIds.contains(stableId)) {
        continue;
      }

      // Overlap check against existing activities
      final overlap = TimeUtils.checkOverlap(
        startMinute: rule.startMinute,
        endMinute: rule.endMinute,
        existingActivities: existing,
      );

      if (overlap.hasOverlap) {
        // Respect scheduling rules: do not silently overwrite
        continue;
      }

      final Activity recurringAct = Activity(
        id: stableId,
        title: rule.title,
        category: rule.category,
        date: normalized,
        startMinute: rule.startMinute,
        endMinute: rule.endMinute,
        notes: rule.notes,
        isCompleted: false,
        priority: rule.priority,
        reminderOffsetMinutes: rule.reminderOffsetMinutes,
        recurrenceRuleId: rule.id,
        isRecurrenceInstance: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveActivity(recurringAct);
      existing.add(recurringAct);
      existingIds.add(stableId);
      generatedCount++;
    }

    return generatedCount;
  }

  // Daily Review
  @override
  Future<DailyReview?> getDailyReview(DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    final query = _db.select(_db.dailyReviewsTable)
      ..where((tbl) => tbl.date.equals(normalized));
    final entry = await query.getSingleOrNull();
    return entry != null ? _mapReviewEntryToDomain(entry) : null;
  }

  @override
  Future<void> saveDailyReview(DailyReview review) async {
    await _db
        .into(_db.dailyReviewsTable)
        .insertOnConflictUpdate(_mapReviewDomainToCompanion(review));
  }
}
