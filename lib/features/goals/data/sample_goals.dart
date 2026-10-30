import '../../schedule/domain/activity_priority.dart';
import '../../schedule/domain/time_utils.dart';
import '../domain/goal.dart';
import '../domain/goal_category.dart';
import '../domain/goal_milestone.dart';
import '../domain/goal_status.dart';

class SampleGoals {
  SampleGoals._();

  static List<Goal> getDefaultGoals() {
    final DateTime now = TimeUtils.normalizeDate(DateTime.now());

    return [
      Goal(
        id: 'sample_goal_leetcode',
        title: 'Master 50 LeetCode Problems',
        description:
            'Focus on core data structures for technical interview preparation.',
        category: GoalCategory.coding,
        status: GoalStatus.active,
        priority: ActivityPriority.high,
        targetValue: 50.0,
        currentValue: 24.0,
        unit: 'problems',
        startDate: now.subtract(const Duration(days: 7)),
        targetDate: now.add(const Duration(days: 21)),
        notes: 'Track patterns: Sliding window, BFS/DFS, Top-K elements.',
        milestones: [
          GoalMilestone(
            id: 'm-lc-1',
            goalId: 'sample_goal_leetcode',
            title: 'Arrays & Two Pointers (15 problems)',
            isCompleted: true,
            orderIndex: 0,
            completedAt: now.subtract(const Duration(days: 2)),
          ),
          GoalMilestone(
            id: 'm-lc-2',
            goalId: 'sample_goal_leetcode',
            title: 'Binary Trees & Graphs (20 problems)',
            isCompleted: false,
            orderIndex: 1,
            targetDate: now.add(const Duration(days: 10)),
          ),
          GoalMilestone(
            id: 'm-lc-3',
            goalId: 'sample_goal_leetcode',
            title: 'Dynamic Programming & Memoization (15 problems)',
            isCompleted: false,
            orderIndex: 2,
            targetDate: now.add(const Duration(days: 21)),
          ),
        ],
      ),
      Goal(
        id: 'sample_goal_systems',
        title: 'Distributed Systems Deep Dive',
        description:
            'Read Designing Data-Intensive Applications and paper reviews.',
        category: GoalCategory.academics,
        status: GoalStatus.active,
        priority: ActivityPriority.medium,
        targetValue: 30.0,
        currentValue: 14.5,
        unit: 'hours',
        startDate: now.subtract(const Duration(days: 10)),
        targetDate: now.add(const Duration(days: 14)),
        milestones: [
          GoalMilestone(
            id: 'm-sys-1',
            goalId: 'sample_goal_systems',
            title: 'Replication & Partitioning (Part II)',
            isCompleted: true,
            orderIndex: 0,
            completedAt: now.subtract(const Duration(days: 3)),
          ),
          GoalMilestone(
            id: 'm-sys-2',
            goalId: 'sample_goal_systems',
            title: 'Transactions & Consensus (Part III)',
            isCompleted: false,
            orderIndex: 1,
            targetDate: now.add(const Duration(days: 7)),
          ),
        ],
      ),
      Goal(
        id: 'sample_goal_app',
        title: 'Finish Mobile App Portfolio',
        description: 'Complete Dayweaver with offline-first persistence.',
        category: GoalCategory.projects,
        status: GoalStatus.active,
        priority: ActivityPriority.high,
        targetValue: 5.0,
        currentValue: 3.0,
        unit: 'milestones',
        startDate: now.subtract(const Duration(days: 14)),
        targetDate: now.add(const Duration(days: 5)),
        milestones: [
          GoalMilestone(
            id: 'm-app-1',
            goalId: 'sample_goal_app',
            title: 'Daily Timeline & Drift Schema',
            isCompleted: true,
            orderIndex: 0,
            completedAt: now.subtract(const Duration(days: 10)),
          ),
          GoalMilestone(
            id: 'm-app-2',
            goalId: 'sample_goal_app',
            title: 'Routine Templates & Conflict Handling',
            isCompleted: true,
            orderIndex: 1,
            completedAt: now.subtract(const Duration(days: 5)),
          ),
          GoalMilestone(
            id: 'm-app-3',
            goalId: 'sample_goal_app',
            title: 'Goals & Progress Tracking System',
            isCompleted: false,
            orderIndex: 2,
            targetDate: now.add(const Duration(days: 2)),
          ),
        ],
      ),
    ];
  }
}
