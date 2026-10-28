import 'package:dayweaver/features/schedule/data/activity_repository.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/batch_operation_result.dart';
import 'package:dayweaver/features/schedule/domain/conflict_strategy.dart';
import 'package:dayweaver/features/schedule/domain/daily_review.dart';
import 'package:dayweaver/features/schedule/domain/recurrence_rule.dart';
import 'package:dayweaver/features/schedule/domain/routine_template.dart';
import 'package:dayweaver/features/schedule/domain/routine_template_block.dart';
import 'package:dayweaver/features/schedule/domain/time_utils.dart';

class FakeActivityRepository implements ActivityRepository {
  final List<Activity> saved = [];
  final List<RoutineTemplate> savedTemplates = [];
  final List<RecurrenceRule> savedRules = [];
  final Map<DateTime, DailyReview> savedReviews = {};
  final Set<String> recurrenceExceptions = {};

  @override
  Future<int> countActivities() async => saved.length;

  @override
  Future<void> deleteActivity(String id) async {
    saved.removeWhere((Activity a) => a.id == id);
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    return saved.where((Activity a) => a.id == id).firstOrNull;
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    return saved
        .where(
          (Activity a) =>
              TimeUtils.normalizeDate(a.date).isAtSameMomentAs(normalized),
        )
        .toList();
  }

  @override
  Future<List<Activity>> getActivitiesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final DateTime normStart = TimeUtils.normalizeDate(startDate);
    final DateTime normEnd = TimeUtils.normalizeDate(endDate);

    return saved.where((Activity a) {
      final DateTime d = TimeUtils.normalizeDate(a.date);
      return !d.isBefore(normStart) && !d.isAfter(normEnd);
    }).toList();
  }

  @override
  Stream<List<Activity>> watchActivitiesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return Stream.fromFuture(getActivitiesForDateRange(startDate, endDate));
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    saved.removeWhere((Activity a) => a.id == activity.id);
    saved.add(activity);
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    final int idx = saved.indexWhere((Activity a) => a.id == id);
    if (idx != -1) {
      saved[idx] = saved[idx].copyWith(isCompleted: isCompleted);
    }
  }

  @override
  Stream<List<Activity>> watchActivitiesForDate(DateTime date) {
    return Stream.fromFuture(getActivitiesForDate(date));
  }

  @override
  Future<Activity> duplicateActivity(
    String id, {
    DateTime? targetDate,
    int? targetStartMinute,
  }) async {
    final Activity act = saved.firstWhere((Activity a) => a.id == id);
    final Activity copy = act.copyWith(
      id: 'copy-${act.id}',
      title: '${act.title} (Copy)',
      date: targetDate ?? act.date,
      startMinute: targetStartMinute ?? act.startMinute,
      isCompleted: false,
    );
    saved.add(copy);
    return copy;
  }

  @override
  Future<void> moveActivity(
    String id, {
    required DateTime newDate,
    required int newStartMinute,
    required int newEndMinute,
  }) async {
    final int index = saved.indexWhere((Activity a) => a.id == id);
    if (index != -1) {
      saved[index] = saved[index].copyWith(
        date: newDate,
        startMinute: newStartMinute,
        endMinute: newEndMinute,
      );
    }
  }

  @override
  Future<Set<DateTime>> getDatesWithActivities(
    DateTime startRange,
    DateTime endRange,
  ) async {
    final Set<DateTime> result = {};
    for (final Activity a in saved) {
      final DateTime norm = TimeUtils.normalizeDate(a.date);
      if (!norm.isBefore(startRange) && !norm.isAfter(endRange)) {
        result.add(norm);
      }
    }
    return result;
  }

  // Routine Templates
  @override
  Stream<List<RoutineTemplate>> watchTemplates() =>
      Stream.value(savedTemplates);

  @override
  Future<List<RoutineTemplate>> getTemplates() async => savedTemplates;

  @override
  Future<RoutineTemplate?> getTemplateById(String id) async {
    return savedTemplates.where((RoutineTemplate t) => t.id == id).firstOrNull;
  }

  @override
  Future<void> saveTemplate(RoutineTemplate template) async {
    savedTemplates.removeWhere((RoutineTemplate t) => t.id == template.id);
    savedTemplates.add(template);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    savedTemplates.removeWhere((RoutineTemplate t) => t.id == id);
  }

  @override
  Future<void> saveTemplateBlock(RoutineTemplateBlock block) async {
    final int idx = savedTemplates.indexWhere(
      (RoutineTemplate t) => t.id == block.templateId,
    );
    if (idx != -1) {
      final List<RoutineTemplateBlock> blocks = List.from(
        savedTemplates[idx].blocks,
      );
      blocks.removeWhere((RoutineTemplateBlock b) => b.id == block.id);
      blocks.add(block);
      savedTemplates[idx] = savedTemplates[idx].copyWith(blocks: blocks);
    }
  }

  @override
  Future<void> deleteTemplateBlock(String blockId) async {
    for (int i = 0; i < savedTemplates.length; i++) {
      final List<RoutineTemplateBlock> blocks = savedTemplates[i].blocks
          .where((RoutineTemplateBlock b) => b.id != blockId)
          .toList();
      savedTemplates[i] = savedTemplates[i].copyWith(blocks: blocks);
    }
  }

  @override
  Future<int> countTemplates() async => savedTemplates.length;

  @override
  Future<BatchOperationResult> applyTemplateToDate({
    required String templateId,
    required DateTime date,
    required ConflictStrategy conflictStrategy,
  }) async {
    final RoutineTemplate? template = await getTemplateById(templateId);
    if (template == null) {
      return BatchOperationResult.failure('Template not found');
    }

    for (final RoutineTemplateBlock b in template.blocks) {
      saved.add(
        Activity(
          id: 'applied-${b.id}',
          title: b.title,
          category: b.category,
          date: TimeUtils.normalizeDate(date),
          startMinute: b.startMinute,
          endMinute: b.endMinute,
          notes: b.notes,
          priority: b.priority,
        ),
      );
    }
    return BatchOperationResult.success(addedCount: template.blocks.length);
  }

  @override
  Future<BatchOperationResult> copySchedule({
    required DateTime fromDate,
    required DateTime toDate,
    required ConflictStrategy conflictStrategy,
  }) async {
    final List<Activity> src = await getActivitiesForDate(fromDate);
    for (final Activity a in src) {
      saved.add(
        a.copyWith(
          id: 'copied-${a.id}',
          date: TimeUtils.normalizeDate(toDate),
          isCompleted: false,
        ),
      );
    }
    return BatchOperationResult.success(addedCount: src.length);
  }

  // Recurrence
  @override
  Stream<List<RecurrenceRule>> watchRecurrenceRules() =>
      Stream.value(savedRules);

  @override
  Future<List<RecurrenceRule>> getRecurrenceRules() async => savedRules;

  @override
  Future<RecurrenceRule?> getRecurrenceRuleById(String id) async {
    return savedRules.where((RecurrenceRule r) => r.id == id).firstOrNull;
  }

  @override
  Future<void> saveRecurrenceRule(RecurrenceRule rule) async {
    savedRules.removeWhere((RecurrenceRule r) => r.id == rule.id);
    savedRules.add(rule);
  }

  @override
  Future<void> deleteRecurrenceRule(String id) async {
    savedRules.removeWhere((RecurrenceRule r) => r.id == id);
  }

  @override
  Future<void> toggleRecurrenceRuleEnabled(String id, bool isEnabled) async {
    final int idx = savedRules.indexWhere((RecurrenceRule r) => r.id == id);
    if (idx != -1) {
      savedRules[idx] = savedRules[idx].copyWith(isEnabled: isEnabled);
    }
  }

  @override
  Future<void> addRecurrenceException(String ruleId, DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    recurrenceExceptions.add(
      '${ruleId}_${normalized.year}_${normalized.month}_${normalized.day}',
    );
  }

  @override
  Future<int> generateRecurringActivitiesForDate(DateTime date) async {
    final DateTime normalized = TimeUtils.normalizeDate(date);
    int generated = 0;
    for (final RecurrenceRule rule in savedRules) {
      if (!rule.matchesDate(normalized)) continue;
      final String excKey =
          '${rule.id}_${normalized.year}_${normalized.month}_${normalized.day}';
      if (recurrenceExceptions.contains(excKey)) continue;

      final String stableId = 'rec_${rule.id}_${normalized.day}';
      if (saved.any((Activity a) => a.id == stableId)) continue;

      saved.add(
        Activity(
          id: stableId,
          title: rule.title,
          category: rule.category,
          date: normalized,
          startMinute: rule.startMinute,
          endMinute: rule.endMinute,
          notes: rule.notes,
          priority: rule.priority,
          recurrenceRuleId: rule.id,
          isRecurrenceInstance: true,
        ),
      );
      generated++;
    }
    return generated;
  }

  // Daily Review
  @override
  Future<DailyReview?> getDailyReview(DateTime date) async {
    return savedReviews[TimeUtils.normalizeDate(date)];
  }

  @override
  Future<void> saveDailyReview(DailyReview review) async {
    savedReviews[TimeUtils.normalizeDate(review.date)] = review;
  }
}
