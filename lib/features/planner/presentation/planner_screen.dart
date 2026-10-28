import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/activity_details_sheet.dart';
import '../../../shared/widgets/activity_form_sheet.dart';
import '../../schedule/domain/time_utils.dart';
import '../../schedule/presentation/activity_providers.dart';
import '../../schedule/presentation/routine_templates_screen.dart';
import '../../schedule/presentation/widgets/copy_schedule_sheet.dart';
import '../../today/presentation/widgets/day_summary_card.dart';
import 'widgets/planner_month_calendar.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(plannerSelectedDateProvider);
    final today = TimeUtils.normalizeDate(DateTime.now());
    final isToday = selectedDate.isAtSameMomentAs(today);

    final activitiesAsync = ref.watch(activitiesForPlannerDateProvider);
    final metrics = ref.watch(plannerDayMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Planner', style: AppTypography.headingMedium),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineTemplatesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
            label: const Text('Routines'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy Schedule to Another Date',
            onPressed: () {
              CopyScheduleSheet.show(context, initialSourceDate: selectedDate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Compact Monthly Calendar
          SliverToBoxAdapter(
            child: PlannerMonthCalendar(
              selectedDate: selectedDate,
              onDateSelected: (date) {
                ref.read(plannerSelectedDateProvider.notifier).state = date;
              },
            ),
          ),

          // 2. Selected Date Header Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isToday
                            ? 'Today’s Plan'
                            : '${DateFormat('EEEE').format(selectedDate)} Schedule',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  if (!isToday)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(plannerSelectedDateProvider.notifier).state =
                            today;
                      },
                      icon: const Icon(Icons.today_rounded, size: 14),
                      label: const Text('Today'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.surfaceSecondary,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Day Flow Summary Card for the selected date
          SliverToBoxAdapter(child: DaySummaryCard(overrideMetrics: metrics)),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 4. Daily Schedule Preview List
          activitiesAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium),
              ),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 42,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Activities Scheduled',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This day is completely free (24 hours unscheduled).',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RoutineTemplatesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.dashboard_customize_outlined,
                                size: 16,
                              ),
                              label: const Text('Apply Routine'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                CopyScheduleSheet.show(
                                  context,
                                  initialSourceDate: today,
                                  initialTargetDate: selectedDate,
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Copy Schedule'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                ActivityFormSheet.show(
                                  context,
                                  initialDate: selectedDate,
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Activity'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final act = activities[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: act.isCompleted
                            ? AppColors.surfaceElevated.withValues(alpha: 0.8)
                            : act.category.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: act.isCompleted
                              ? AppColors.borderSubtle
                              : act.category.borderColor,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => ActivityDetailsSheet.show(context, act),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: act.category.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${act.startFormatted} – ${act.endFormatted} (${act.durationFormatted})',
                                          style: AppTypography.timeLabel
                                              .copyWith(
                                                color: act.isCompleted
                                                    ? AppColors.textMuted
                                                    : act.category.color,
                                                fontSize: 11,
                                              ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: act.category.color
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            act.category.displayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: act.category.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      act.title,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: act.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: act.isCompleted
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  act.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: act.isCompleted
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref
                                      .read(activityRepositoryProvider)
                                      .toggleCompletion(
                                        act.id,
                                        !act.isCompleted,
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: activities.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ActivityFormSheet.show(context, initialDate: selectedDate);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Activity',
        child: const Icon(Icons.add),
      ),
    );
  }
}
