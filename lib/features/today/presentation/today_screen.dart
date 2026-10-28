import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../schedule/presentation/activity_providers.dart';
import '../../../shared/widgets/activity_form_sheet.dart';
import 'widgets/day_header.dart';
import 'widgets/day_summary_card.dart';
import 'widgets/daily_timeline_view.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesForSelectedDateProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DayHeader(),
            const DaySummaryCard(),
            const SizedBox(height: 8),
            Expanded(
              child: activitiesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load schedule',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(activitiesForSelectedDateProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (activities) => DailyTimelineView(
                  activities: activities,
                  date: selectedDate,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ActivityFormSheet.show(context, initialDate: selectedDate);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Activity',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
