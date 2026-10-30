import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../schedule/data/activity_repository.dart';
import '../../schedule/domain/activity.dart';
import '../../schedule/presentation/activity_providers.dart';
import '../data/goal_repository.dart';
import '../domain/goal.dart';
import '../domain/goal_milestone.dart';
import '../domain/goal_progress_update.dart';
import '../domain/goal_status.dart';
import 'goal_providers.dart';
import 'widgets/add_edit_goal_sheet.dart';
import 'widgets/add_milestone_sheet.dart';
import 'widgets/link_activity_sheet.dart';
import 'widgets/record_progress_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Goal>> allGoalsAsync = ref.watch(
      allGoalsStreamProvider,
    );
    final GoalRepository repo = ref.watch(goalRepositoryProvider);
    final ActivityRepository activityRepo = ref.watch(
      activityRepositoryProvider,
    );

    return allGoalsAsync.when(
      data: (List<Goal> goals) {
        final Goal? goal = goals.where((Goal g) => g.id == goalId).firstOrNull;

        if (goal == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(child: Text('Goal not found.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              goal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Goal',
                onPressed: () => AddEditGoalSheet.show(context, goal: goal),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (BuildContext ctx) => [
                  if (goal.status.canPause)
                    const PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Pause Goal'),
                        ],
                      ),
                    ),
                  if (goal.status.canResume)
                    const PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Resume Goal'),
                        ],
                      ),
                    ),
                  if (goal.status != GoalStatus.completed)
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as Completed'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'reopen',
                      child: Row(
                        children: [
                          Icon(Icons.replay_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Reopen as Active'),
                        ],
                      ),
                    ),
                  if (goal.status.canArchive)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Archive Goal'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Goal',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (String val) =>
                    _handleMenuAction(context, repo, goal, val),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Meta Header Card
              _buildMetaCard(goal),
              const SizedBox(height: 16),

              // Progress Card
              _buildProgressCard(context, goal),
              const SizedBox(height: 20),

              // Milestones Section
              _buildMilestonesSection(context, ref, repo, goal),
              const SizedBox(height: 20),

              // Progress History Section
              _buildHistorySection(ref, goal),
              const SizedBox(height: 20),

              // Linked Activities Section
              _buildLinkedActivitiesSection(context, repo, activityRepo, goal),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMetaCard(Goal goal) {
    Color statusColor = AppColors.primary;
    if (goal.status.isCompleted) statusColor = AppColors.secondary;
    if (goal.status.isPaused) statusColor = AppColors.warning;
    if (goal.status.isArchived) statusColor = AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: goal.category.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      goal.category.icon,
                      size: 14,
                      color: goal.category.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      goal.category.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: goal.category.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.title,
            style: AppTypography.headingSmall.copyWith(fontSize: 20),
          ),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              goal.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Priority: ${goal.priority.displayName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Started ${DateFormat('MMM d, yyyy').format(goal.startDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, Goal goal) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress Tracker', style: AppTypography.titleMedium),
              Text(
                '${goal.progressPercent}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: goal.isTargetReached
                      ? AppColors.secondary
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressRatio,
              minHeight: 10,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isTargetReached ? AppColors.secondary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.formattedProgress,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                goal.isTargetReached
                    ? 'Target achieved!'
                    : goal.formattedRemaining,
                style: TextStyle(
                  fontSize: 12,
                  color: goal.isTargetReached
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  fontWeight: goal.isTargetReached
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: goal.isPastDeadline
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 16,
                    color: goal.isPastDeadline
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    goal.isPastDeadline
                        ? 'Overdue since ${DateFormat('MMM d').format(goal.targetDate!)}'
                        : 'Target deadline: ${DateFormat('MMM d, yyyy').format(goal.targetDate!)} (${goal.daysRemaining} days remaining)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: goal.isPastDeadline
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => RecordProgressSheet.show(context, goal),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Update Progress'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(
    BuildContext context,
    WidgetRef ref,
    GoalRepository repo,
    Goal goal,
  ) {
    final AsyncValue<List<GoalMilestone>> milestonesAsync = ref.watch(
      goalMilestonesStreamProvider(goal.id),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Milestones', style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.milestonesCompletedCount} of ${goal.milestonesTotalCount} completed (${goal.milestoneProgressPercent}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Add Milestone',
                onPressed: () => AddMilestoneSheet.show(
                  context,
                  goalId: goal.id,
                  nextOrderIndex: goal.milestones.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          milestonesAsync.when(
            data: (List<GoalMilestone> milestones) {
              if (milestones.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No milestones added yet. Break down this goal into tangible steps.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return Column(
                children: milestones.map((GoalMilestone m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: m.isCompleted
                          ? AppColors.secondary.withValues(alpha: 0.08)
                          : AppColors.surfaceSecondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: m.isCompleted
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      leading: Checkbox(
                        value: m.isCompleted,
                        activeColor: AppColors.secondary,
                        onChanged: (bool? val) {
                          if (val != null) {
                            repo.toggleMilestone(m.id, val);
                          }
                        },
                      ),
                      title: Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: m.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: m.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: m.targetDate != null
                          ? Text(
                              'Target: ${DateFormat('MMM d').format(m.targetDate!)}',
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 18),
                        itemBuilder: (BuildContext ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                        onSelected: (String val) {
                          if (val == 'edit') {
                            AddMilestoneSheet.show(
                              context,
                              goalId: goal.id,
                              milestone: m,
                            );
                          } else if (val == 'delete') {
                            repo.deleteMilestone(m.id);
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object err, _) => Text('Error loading milestones: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(WidgetRef ref, Goal goal) {
    final AsyncValue<List<GoalProgressUpdate>> historyAsync = ref.watch(
      goalProgressUpdatesStreamProvider(goal.id),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress History', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          historyAsync.when(
            data: (List<GoalProgressUpdate> updates) {
              if (updates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No progress updates recorded yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: updates.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (BuildContext context, int index) {
                  final GoalProgressUpdate u = updates[index];
                  final String dateFormatted = DateFormat(
                    'MMM d, h:mm a',
                  ).format(u.createdAt);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u.changeFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resulting: ${u.resultingValue.toStringAsFixed(1)} ${goal.unit}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (u.note != null && u.note!.isNotEmpty)
                              Text(
                                u.note!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object err, _) => Text('Error loading history: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedActivitiesSection(
    BuildContext context,
    GoalRepository repo,
    ActivityRepository activityRepo,
    Goal goal,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Linked Schedule Blocks', style: AppTypography.titleMedium),
              TextButton.icon(
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Link Activity'),
                onPressed: () => LinkActivitySheet.show(context, goal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: repo.getLinkedActivityIdsForGoal(goal.id),
            builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              final List<String> linkedIds = snapshot.data ?? [];
              if (linkedIds.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No activities linked to this goal yet. Connect your study sessions or project blocks to track dedication.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return FutureBuilder<List<Activity?>>(
                future: Future.wait(
                  linkedIds.map(
                    (String id) => activityRepo.getActivityById(id),
                  ),
                ),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Activity?>> actsSnapshot,
                    ) {
                      final List<Activity> activities =
                          (actsSnapshot.data ?? [])
                              .whereType<Activity>()
                              .toList();

                      if (activities.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: activities.map((Activity act) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: act.category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${DateFormat('MMM d').format(act.date)} · ${act.startFormatted} - ${act.endFormatted}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.link_off_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  tooltip: 'Unlink',
                                  onPressed: () {
                                    repo.unlinkActivityFromGoal(
                                      act.id,
                                      goal.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    GoalRepository repo,
    Goal goal,
    String action,
  ) {
    if (action == 'pause') {
      repo.updateGoalStatus(goal.id, GoalStatus.paused);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Goal "${goal.title}" paused.')));
    } else if (action == 'resume') {
      repo.updateGoalStatus(goal.id, GoalStatus.active);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Goal "${goal.title}" resumed.')));
    } else if (action == 'complete') {
      repo.updateGoalStatus(goal.id, GoalStatus.completed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal "${goal.title}" marked completed!')),
      );
    } else if (action == 'reopen') {
      repo.updateGoalStatus(goal.id, GoalStatus.active);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal "${goal.title}" reopened as active.')),
      );
    } else if (action == 'archive') {
      repo.updateGoalStatus(goal.id, GoalStatus.archived);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Goal "${goal.title}" archived.')));
    } else if (action == 'delete') {
      _confirmDelete(context, repo, goal);
    }
  }

  void _confirmDelete(BuildContext context, GoalRepository repo, Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? All milestones and progress history for this goal will be removed. Associated schedule activities will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              repo.deleteGoal(goal.id);
              Navigator.pop(context); // Exit detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Goal "${goal.title}" deleted.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
