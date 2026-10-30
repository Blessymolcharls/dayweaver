import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../domain/goal.dart';
import '../domain/goal_status.dart';
import 'goal_detail_screen.dart';
import 'goal_providers.dart';
import 'widgets/add_edit_goal_sheet.dart';
import 'widgets/record_progress_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsStreamProvider);
    final filteredGoals = ref.watch(filteredGoalsProvider);
    final metrics = ref.watch(goalsOverviewMetricsProvider);
    final activeFilter = ref.watch(goalFilterStatusProvider);
    final searchQuery = ref.watch(goalSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Goals & Milestones', style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Goal',
            onPressed: () {
              AddEditGoalSheet.show(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddEditGoalSheet.show(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.flag_rounded),
        label: Text(
          'New Goal',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
      body: goalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text('Failed to load goals', style: AppTypography.headingSmall),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (allGoals) {
          return CustomScrollView(
            slivers: [
              // 1. Overview summary banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _GoalsSummaryBanner(metrics: metrics),
                ),
              ),

              // 2. Search & Filter controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged: (val) {
                          ref.read(goalSearchQueryProvider.notifier).state =
                              val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search goals or categories...',
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    ref
                                            .read(
                                              goalSearchQueryProvider.notifier,
                                            )
                                            .state =
                                        '';
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Status filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${allGoals.length})',
                              isSelected: activeFilter == null,
                              onSelected: () =>
                                  ref
                                          .read(
                                            goalFilterStatusProvider.notifier,
                                          )
                                          .state =
                                      null,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Active (${metrics.activeCount})',
                              isSelected: activeFilter == GoalStatus.active,
                              onSelected: () =>
                                  ref
                                      .read(goalFilterStatusProvider.notifier)
                                      .state = GoalStatus
                                      .active,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Completed (${metrics.completedCount})',
                              isSelected: activeFilter == GoalStatus.completed,
                              onSelected: () =>
                                  ref
                                      .read(goalFilterStatusProvider.notifier)
                                      .state = GoalStatus
                                      .completed,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Paused',
                              isSelected: activeFilter == GoalStatus.paused,
                              onSelected: () =>
                                  ref
                                      .read(goalFilterStatusProvider.notifier)
                                      .state = GoalStatus
                                      .paused,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Archived',
                              isSelected: activeFilter == GoalStatus.archived,
                              onSelected: () =>
                                  ref
                                      .read(goalFilterStatusProvider.notifier)
                                      .state = GoalStatus
                                      .archived,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // 3. Goal cards or empty state
              if (filteredGoals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            searchQuery.isNotEmpty || activeFilter != null
                                ? Icons.filter_list_off_rounded
                                : Icons.flag_outlined,
                            size: 56,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty || activeFilter != null
                                ? 'No matching goals found'
                                : 'Set your first goal',
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty || activeFilter != null
                                ? 'Try adjusting your search terms or filter selection.'
                                : 'Define measurable targets for academics, coding, projects, and personal growth.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (searchQuery.isEmpty && activeFilter == null) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () {
                                AddEditGoalSheet.show(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Create Goal'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final goal = filteredGoals[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(
                          goal: goal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GoalDetailScreen(goalId: goal.id),
                              ),
                            );
                          },
                          onQuickProgress: () {
                            RecordProgressSheet.show(context, goal);
                          },
                        ),
                      );
                    }, childCount: filteredGoals.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsSummaryBanner extends StatelessWidget {
  final GoalsOverviewMetrics metrics;

  const _GoalsSummaryBanner({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Focus & Progress',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${metrics.averageProgressPercent.toStringAsFixed(0)}% Avg Progress',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Active',
                  value: '${metrics.activeCount}',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Completed',
                  value: '${metrics.completedCount}',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Due Soon',
                  value: '${metrics.upcomingDeadlinesCount}',
                  icon: Icons.alarm_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onQuickProgress;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onQuickProgress,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = goal.category.color;
    final progress = goal.progressRatio;
    final daysRemaining = goal.daysRemaining;

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category tag and status badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    goal.category.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _GoalStatusBadge(status: goal.status),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                goal.title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: goal.isArchived
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  decoration: goal.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),

              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  goal.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? AppColors.secondary : categoryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Metrics row: current/target + quick update button
              Row(
                children: [
                  Text(
                    '${goal.formattedCurrent} / ${goal.formattedTarget}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${goal.progressPercent.toStringAsFixed(0)}%)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),

                  // Deadline pill if applicable
                  if (daysRemaining != null &&
                      !goal.isCompleted &&
                      !goal.isArchived) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: daysRemaining < 0
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : (daysRemaining <= 3
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.surfaceSecondary),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        daysRemaining < 0
                            ? 'Overdue'
                            : (daysRemaining == 0
                                  ? 'Due today'
                                  : '$daysRemaining d left'),
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: daysRemaining <= 3
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Quick + Progress button
                  if (!goal.isCompleted && !goal.isArchived)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Record Progress',
                      color: AppColors.primary,
                      onPressed: onQuickProgress,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalStatusBadge extends StatelessWidget {
  final GoalStatus status;

  const _GoalStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case GoalStatus.active:
        bg = AppColors.secondary.withValues(alpha: 0.15);
        fg = AppColors.secondary;
        break;
      case GoalStatus.paused:
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textMuted;
        break;
      case GoalStatus.completed:
        bg = AppColors.secondary.withValues(alpha: 0.2);
        fg = AppColors.secondary;
        break;
      case GoalStatus.archived:
        bg = AppColors.surfaceSecondary;
        fg = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
