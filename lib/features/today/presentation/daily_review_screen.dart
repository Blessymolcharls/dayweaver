import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../schedule/data/activity_repository.dart';
import '../../schedule/domain/activity.dart';
import '../../schedule/domain/daily_review.dart';
import '../../schedule/domain/time_utils.dart';
import '../../schedule/presentation/activity_providers.dart';

class DailyReviewScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const DailyReviewScreen({super.key, this.initialDate});

  @override
  ConsumerState<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends ConsumerState<DailyReviewScreen> {
  late DateTime _currentDate;
  final TextEditingController _reflectionController = TextEditingController();
  bool _isSavingReflection = false;

  @override
  void initState() {
    super.initState();
    _currentDate = TimeUtils.normalizeDate(
      widget.initialDate ?? DateTime.now(),
    );
    _loadExistingReview();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final ActivityRepository repo = ref.read(activityRepositoryProvider);
    final DailyReview? review = await repo.getDailyReview(_currentDate);
    if (mounted && review != null && review.reflectionNotes != null) {
      _reflectionController.text = review.reflectionNotes!;
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: offsetDays));
      _reflectionController.clear();
    });
    _loadExistingReview();
  }

  @override
  Widget build(BuildContext context) {
    final ActivityRepository repo = ref.watch(activityRepositoryProvider);
    final Stream<List<Activity>> activitiesStream = repo.watchActivitiesForDate(
      _currentDate,
    );

    final bool isToday = TimeUtils.normalizeDate(
      _currentDate,
    ).isAtSameMomentAs(TimeUtils.normalizeDate(DateTime.now()));
    final String dateFormatted = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(_currentDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daily Review')),
      body: StreamBuilder<List<Activity>>(
        stream: activitiesStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<Activity>> snapshot) {
              final List<Activity> activities = snapshot.data ?? [];
              final DayMetrics metrics = calculateDayMetrics(activities);

              final List<Activity> completedActs = activities
                  .where((Activity a) => a.isCompleted)
                  .toList();
              final List<Activity> unfinishedActs = activities
                  .where((Activity a) => !a.isCompleted)
                  .toList();

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // Date Navigator Banner
                  _buildDateNavigator(dateFormatted, isToday),
                  const SizedBox(height: 16),

                  // Overview Progress Card
                  _buildOverviewCard(metrics),
                  const SizedBox(height: 20),

                  // Completed Activities Section
                  _buildSectionHeader(
                    title: 'Completed (${completedActs.length})',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 8),
                  if (completedActs.isEmpty)
                    _buildEmptyCard('No activities completed yet on this day.')
                  else
                    ...completedActs.map(
                      (Activity act) => _buildCompletedCard(act),
                    ),
                  const SizedBox(height: 20),

                  // Unfinished Activities Section
                  _buildSectionHeader(
                    title: 'Unfinished (${unfinishedActs.length})',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  if (unfinishedActs.isEmpty)
                    _buildEmptyCard(
                      'All planned activities were accomplished! 🎉',
                    )
                  else
                    ...unfinishedActs.map(
                      (Activity act) => _buildUnfinishedCard(act, repo),
                    ),
                  const SizedBox(height: 20),

                  // Reflection & Notes
                  _buildReflectionSection(metrics, repo),
                  const SizedBox(height: 24),

                  // Prepare Tomorrow Action
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _prepareTomorrowPlan(context),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Prepare Tomorrow\'s Plan'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
      ),
    );
  }

  Widget _buildDateNavigator(String dateFormatted, bool isToday) {
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
            onPressed: () => _changeDate(-1),
            tooltip: 'Previous Day',
          ),
          Column(
            children: [
              Text(
                dateFormatted,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _changeDate(1),
            tooltip: 'Next Day',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DayMetrics metrics) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day Flow Summary',
                style: AppTypography.headingSmall.copyWith(fontSize: 18),
              ),
              Text(
                '${metrics.completionPercent}% Completed',
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
              value: metrics.completionRatio,
              minHeight: 8,
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
                child: _buildMetricItem(
                  'Planned',
                  metrics.plannedDurationFormatted,
                  Icons.schedule_rounded,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Accomplished',
                  metrics.completedDurationFormatted,
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Free Time',
                  metrics.freeDurationFormatted,
                  Icons.spa_outlined,
                ),
              ),
            ],
          ),
          if (metrics.categoryAllocations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Time by Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: metrics.categoryAllocations.map((alloc) {
                return Chip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: alloc.category.surfaceColor,
                  avatar: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: alloc.category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(
                    '${alloc.category.displayName} ${alloc.percentageRound}% (${alloc.durationFormatted})',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCompletedCard(Activity act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${act.startFormatted} - ${act.endFormatted} (${act.durationFormatted})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            act.category.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: act.category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnfinishedCard(Activity act, ActivityRepository repo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${act.startFormatted} - ${act.endFormatted} (${act.durationFormatted})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.forward_rounded, size: 14),
            label: const Text(
              'Move to Tomorrow',
              style: TextStyle(fontSize: 11),
            ),
            onPressed: () => _moveActivityToTomorrow(act, repo),
          ),
        ],
      ),
    );
  }

  Future<void> _moveActivityToTomorrow(
    Activity act,
    ActivityRepository repo,
  ) async {
    final DateTime tomorrow = _currentDate.add(const Duration(days: 1));
    try {
      await repo.moveActivity(
        act.id,
        newDate: tomorrow,
        newStartMinute: act.startMinute,
        newEndMinute: act.endMinute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved "${act.title}" to tomorrow (${DateFormat('MMM d').format(tomorrow)}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildReflectionSection(DayMetrics metrics, ActivityRepository repo) {
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
                Icons.edit_note_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Reflection & Notes',
                style: AppTypography.titleMedium.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'What went well today? What will you adjust tomorrow?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflectionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Jot down personal wins, blockers, or thoughts...',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _isSavingReflection
                  ? null
                  : () => _saveReflection(metrics, repo),
              child: _isSavingReflection
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Reflection'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReflection(
    DayMetrics metrics,
    ActivityRepository repo,
  ) async {
    setState(() => _isSavingReflection = true);
    final DailyReview review = DailyReview(
      date: _currentDate,
      reflectionNotes: _reflectionController.text.trim().isEmpty
          ? null
          : _reflectionController.text.trim(),
      completedTasksCount: metrics.completedActivities,
      totalTasksCount: metrics.totalActivities,
      completedMinutes: metrics.completedMinutes,
      totalPlannedMinutes: metrics.totalPlannedMinutes,
      reviewedAt: DateTime.now(),
    );

    await repo.saveDailyReview(review);
    if (mounted) {
      setState(() => _isSavingReflection = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reflection saved.')));
    }
  }

  void _prepareTomorrowPlan(BuildContext context) {
    final DateTime tomorrow = _currentDate.add(const Duration(days: 1));
    ref.read(plannerSelectedDateProvider.notifier).state = tomorrow;
    Navigator.pop(context);
  }
}
