import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/goal_providers.dart';
import '../../schedule/domain/activity_category.dart';
import '../../schedule/domain/time_utils.dart';
import '../../schedule/domain/weekly_metrics.dart';
import '../../schedule/presentation/activity_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime monday = ref.watch(selectedWeekStartProvider);
    final DateTime sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final WeeklyMetrics weeklyMetrics = ref.watch(weeklyMetricsProvider);

    final String weekRangeString =
        '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Weekly Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'This Week',
            onPressed: () {
              final DateTime now = TimeUtils.normalizeDate(DateTime.now());
              final DateTime thisMonday = DateTime(
                now.year,
                now.month,
                now.day - (now.weekday - 1),
              );
              ref.read(selectedWeekStartProvider.notifier).state = thisMonday;
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Week Navigator Banner
          _buildWeekNavigator(context, ref, monday, weekRangeString),
          const SizedBox(height: 16),

          // High-level completion card
          _buildWeeklySummaryCard(context, weeklyMetrics),
          const SizedBox(height: 20),

          // Daily Comparison Bars
          _buildDailyComparisonCard(context, weeklyMetrics),
          const SizedBox(height: 20),

          // Category Allocation Breakdown
          _buildCategoryAllocationsCard(context, weeklyMetrics),
          const SizedBox(height: 20),

          // Productivity Stats
          _buildProductivityCard(context, weeklyMetrics),
          const SizedBox(height: 20),

          // Goals & Milestones Progress
          _buildGoalProgressCard(context, ref, monday),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(
    BuildContext context,
    WidgetRef ref,
    DateTime monday,
    String weekRangeString,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous Week',
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state = monday
                  .subtract(const Duration(days: 7));
            },
          ),
          Column(
            children: [
              Text(
                weekRangeString,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Week ${DateFormat('w').format(monday)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next Week',
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state = monday.add(
                const Duration(days: 7),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(
    BuildContext context,
    WeeklyMetrics weeklyMetrics,
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
              Text(
                'Weekly Progress',
                style: AppTypography.headingSmall.copyWith(fontSize: 18),
              ),
              Text(
                '${weeklyMetrics.completionPercent}% Accomplished',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: weeklyMetrics.completionRatio,
              minHeight: 10,
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Total Planned',
                  weeklyMetrics.totalPlannedFormatted,
                  Icons.schedule_rounded,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Completed',
                  weeklyMetrics.totalCompletedFormatted,
                  Icons.check_circle_rounded,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Free Time',
                  weeklyMetrics.totalFreeFormatted,
                  Icons.spa_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildDailyComparisonCard(
    BuildContext context,
    WeeklyMetrics weeklyMetrics,
  ) {
    const List<String> dayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final DateTime now = TimeUtils.normalizeDate(DateTime.now());

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
          Text('Daily Overview', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Planned vs. completed hours across each day of the week',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (int index) {
              final DailyOverviewData dayData =
                  weeklyMetrics.dailyBreakdowns[index];
              final bool isToday = dayData.date == now;
              final String completedHours = (dayData.completedMinutes / 60)
                  .toStringAsFixed(1);

              final double barHeightRatio = (dayData.plannedMinutes / 720)
                  .clamp(0.05, 1.0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${dayData.completionPercent}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dayData.plannedMinutes > 0
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 100 * barHeightRatio,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28,
                      height: (100 * barHeightRatio) * dayData.completionRatio,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${completedHours}h',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAllocationsCard(
    BuildContext context,
    WeeklyMetrics weeklyMetrics,
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
          Text('Time Allocation by Category', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          if (weeklyMetrics.categoryMinutes.isEmpty)
            const Text(
              'No activities recorded for this week.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weeklyMetrics.categoryPercentages.entries.map((
                MapEntry<ActivityCategory, int> entry,
              ) {
                final ActivityCategory cat = entry.key;
                final int pct = entry.value;
                final int minutes = weeklyMetrics.categoryMinutes[cat] ?? 0;
                final String formatted = TimeUtils.formatDuration(minutes);

                return Chip(
                  backgroundColor: cat.surfaceColor,
                  avatar: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(
                    '${cat.displayName}: $pct% ($formatted)',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductivityCard(
    BuildContext context,
    WeeklyMetrics weeklyMetrics,
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
          Text('Activity Counts', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${weeklyMetrics.completedActivitiesCount}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${weeklyMetrics.unfinishedActivitiesCount}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Unfinished Tasks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(
    BuildContext context,
    WidgetRef ref,
    DateTime monday,
  ) {
    final goalInsightsAsync = ref.watch(goalWeeklyInsightsProvider(monday));

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
                Icons.flag_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Goal Progress & Milestones',
                style: AppTypography.headingSmall.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          goalInsightsAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'Loading goals...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Failed to load goal metrics: $err',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            data: (insights) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${insights.activeGoalsCount}',
                                style: AppTypography.headingMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Active Goals',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${insights.completedThisWeekCount}',
                                style: AppTypography.headingMedium.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Completed',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${insights.progressUpdatesCount}',
                                style: AppTypography.headingMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Updates',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (insights.approachingDeadlines.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Approaching Deadlines (Next 7 Days)',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...insights.approachingDeadlines.map((goal) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GoalDetailScreen(goalId: goal.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: goal.category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  goal.daysRemaining == 0
                                      ? 'Due today'
                                      : '${goal.daysRemaining}d left',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
