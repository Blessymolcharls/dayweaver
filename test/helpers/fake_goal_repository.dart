import 'dart:async';

import 'package:dayweaver/features/goals/data/goal_repository.dart';
import 'package:dayweaver/features/goals/domain/goal.dart';
import 'package:dayweaver/features/goals/domain/goal_milestone.dart';
import 'package:dayweaver/features/goals/domain/goal_progress_update.dart';
import 'package:dayweaver/features/goals/domain/goal_status.dart';

class FakeGoalRepository implements GoalRepository {
  final Map<String, Goal> _goals = {};
  final Map<String, GoalMilestone> _milestones = {};
  final List<GoalProgressUpdate> _updates = [];
  final Set<String> _activityGoalPairs = {}; // "activityId:goalId"

  final StreamController<List<Goal>> _goalsController =
      StreamController<List<Goal>>.broadcast();
  final Map<String, StreamController<List<GoalMilestone>>>
  _milestonesControllers = {};
  final Map<String, StreamController<List<GoalProgressUpdate>>>
  _updatesControllers = {};

  void _emitGoals() {
    _goalsController.add(_goals.values.toList());
  }

  void _emitMilestones(String goalId) {
    if (_milestonesControllers.containsKey(goalId)) {
      final list = _milestones.values.where((m) => m.goalId == goalId).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _milestonesControllers[goalId]!.add(list);
    }
  }

  void _emitUpdates(String goalId) {
    if (_updatesControllers.containsKey(goalId)) {
      final list = _updates.where((u) => u.goalId == goalId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _updatesControllers[goalId]!.add(list);
    }
  }

  @override
  Stream<List<Goal>> watchGoals({GoalStatus? filterStatus}) async* {
    List<Goal> current = _goals.values.toList();
    if (filterStatus != null) {
      current = current.where((g) => g.status == filterStatus).toList();
    }
    yield current;
    yield* _goalsController.stream.map((list) {
      if (filterStatus != null) {
        return list.where((g) => g.status == filterStatus).toList();
      }
      return list;
    });
  }

  @override
  Future<List<Goal>> getGoals({GoalStatus? filterStatus}) async {
    if (filterStatus != null) {
      return _goals.values.where((g) => g.status == filterStatus).toList();
    }
    return _goals.values.toList();
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    return _goals[id];
  }

  @override
  Future<void> saveGoal(Goal goal) async {
    _goals[goal.id] = goal;
    _emitGoals();
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.remove(id);
    _milestones.removeWhere((_, m) => m.goalId == id);
    _updates.removeWhere((u) => u.goalId == id);
    _activityGoalPairs.removeWhere((pair) => pair.endsWith(':$id'));
    _emitGoals();
  }

  @override
  Future<void> updateGoalStatus(String id, GoalStatus status) async {
    final goal = _goals[id];
    if (goal != null) {
      _goals[id] = goal.copyWith(status: status, updatedAt: DateTime.now());
      _emitGoals();
    }
  }

  @override
  Future<void> recordProgressUpdate({
    required String goalId,
    required double changeAmount,
    required bool isIncremental,
    String? note,
  }) async {
    final goal = _goals[goalId];
    if (goal == null) return;

    final double previous = goal.currentValue;
    final double resulting = isIncremental
        ? (previous + changeAmount)
        : changeAmount;
    final double clamped = resulting < 0 ? 0 : resulting;
    final double delta = isIncremental ? changeAmount : (resulting - previous);

    final update = GoalProgressUpdate(
      id: 'update_${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      changeAmount: delta,
      resultingValue: clamped,
      note: note,
      createdAt: DateTime.now(),
    );
    _updates.add(update);

    final bool shouldComplete = clamped >= goal.targetValue;
    _goals[goalId] = goal.copyWith(
      currentValue: clamped,
      status: shouldComplete ? GoalStatus.completed : goal.status,
      updatedAt: DateTime.now(),
    );

    _emitGoals();
    _emitUpdates(goalId);
  }

  @override
  Stream<List<GoalMilestone>> watchMilestones(String goalId) async* {
    final list = _milestones.values.where((m) => m.goalId == goalId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    yield list;
    if (!_milestonesControllers.containsKey(goalId)) {
      _milestonesControllers[goalId] =
          StreamController<List<GoalMilestone>>.broadcast();
    }
    yield* _milestonesControllers[goalId]!.stream;
  }

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async {
    final list = _milestones.values.where((m) => m.goalId == goalId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<void> saveMilestone(GoalMilestone milestone) async {
    _milestones[milestone.id] = milestone;
    _emitMilestones(milestone.goalId);
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    final m = _milestones.remove(milestoneId);
    if (m != null) {
      _emitMilestones(m.goalId);
    }
  }

  @override
  Future<void> toggleMilestone(String milestoneId, bool isCompleted) async {
    final m = _milestones[milestoneId];
    if (m != null) {
      _milestones[milestoneId] = m.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );
      _emitMilestones(m.goalId);
    }
  }

  @override
  Stream<List<GoalProgressUpdate>> watchProgressUpdates(String goalId) async* {
    final list = _updates.where((u) => u.goalId == goalId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield list;
    if (!_updatesControllers.containsKey(goalId)) {
      _updatesControllers[goalId] =
          StreamController<List<GoalProgressUpdate>>.broadcast();
    }
    yield* _updatesControllers[goalId]!.stream;
  }

  @override
  Future<List<GoalProgressUpdate>> getProgressUpdates(String goalId) async {
    final list = _updates.where((u) => u.goalId == goalId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> linkActivityToGoal(String activityId, String goalId) async {
    _activityGoalPairs.add('$activityId:$goalId');
  }

  @override
  Future<void> unlinkActivityFromGoal(String activityId, String goalId) async {
    _activityGoalPairs.remove('$activityId:$goalId');
  }

  @override
  Future<List<String>> getLinkedGoalIdsForActivity(String activityId) async {
    return _activityGoalPairs
        .where((pair) => pair.startsWith('$activityId:'))
        .map((pair) => pair.split(':')[1])
        .toList();
  }

  @override
  Future<List<String>> getLinkedActivityIdsForGoal(String goalId) async {
    return _activityGoalPairs
        .where((pair) => pair.endsWith(':$goalId'))
        .map((pair) => pair.split(':')[0])
        .toList();
  }

  @override
  Future<List<Goal>> getLinkedGoalsForActivity(String activityId) async {
    final ids = await getLinkedGoalIdsForActivity(activityId);
    return ids.map((id) => _goals[id]).whereType<Goal>().toList();
  }

  @override
  Stream<List<Goal>> watchGoalsForActivity(String activityId) async* {
    final initialIds = _activityGoalPairs
        .where((pair) => pair.startsWith('$activityId:'))
        .map((pair) => pair.split(':')[1])
        .toSet();
    yield _goals.values.where((g) => initialIds.contains(g.id)).toList();
    yield* _goalsController.stream.map((_) {
      final ids = _activityGoalPairs
          .where((pair) => pair.startsWith('$activityId:'))
          .map((pair) => pair.split(':')[1])
          .toSet();
      return _goals.values.where((g) => ids.contains(g.id)).toList();
    });
  }

  @override
  Future<int> getActiveGoalsCount() async {
    return _goals.values.where((g) => g.status == GoalStatus.active).length;
  }

  @override
  Future<int> getCompletedGoalsCountForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return _goals.values.where((g) {
      if (g.status != GoalStatus.completed) return false;
      return g.updatedAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          g.updatedAt.isBefore(end.add(const Duration(seconds: 1)));
    }).length;
  }

  @override
  Future<List<Goal>> getGoalsApproachingDeadline(DateTime deadlineLimit) async {
    return _goals.values.where((g) {
      if (g.status != GoalStatus.active || g.targetDate == null) return false;
      return g.targetDate!.isBefore(deadlineLimit.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<int> getProgressUpdatesCountForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return _updates.where((u) {
      return u.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          u.createdAt.isBefore(end.add(const Duration(seconds: 1)));
    }).length;
  }
}
