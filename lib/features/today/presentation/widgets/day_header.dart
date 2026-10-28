import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../../schedule/presentation/activity_providers.dart';
import '../../../schedule/presentation/recurring_activities_screen.dart';
import '../../../schedule/presentation/routine_templates_screen.dart';
import '../../../schedule/presentation/widgets/copy_schedule_sheet.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../daily_review_screen.dart';

class DayHeader extends ConsumerWidget {
  const DayHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final today = TimeUtils.normalizeDate(DateTime.now());
    final isToday = selectedDate.isAtSameMomentAs(today);

    final dateFormat = DateFormat('EEEE, MMMM d');
    final formattedDate = dateFormat.format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: AppTypography.headingMedium.copyWith(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (!isToday)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).state = today;
                      },
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text('Today'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        backgroundColor: AppColors.surfaceSecondary,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Schedule & settings',
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'review',
                        child: Row(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Daily Review'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'recurring',
                        child: Row(
                          children: [
                            Icon(Icons.repeat_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Recurring Activities'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'routines',
                        child: Row(
                          children: [
                            Icon(Icons.dashboard_customize_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Routine Templates'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Copy Schedule...'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'review') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DailyReviewScreen(initialDate: selectedDate),
                          ),
                        );
                      } else if (val == 'recurring') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecurringActivitiesScreen(),
                          ),
                        );
                      } else if (val == 'routines') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RoutineTemplatesScreen(),
                          ),
                        );
                      } else if (val == 'copy') {
                        CopyScheduleSheet.show(
                          context,
                          initialSourceDate: selectedDate,
                        );
                      } else if (val == 'settings') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = selectedDate
                      .subtract(const Duration(days: 1));
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, size: 20),
                      SizedBox(width: 4),
                      Text('Previous day'),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = selectedDate
                      .add(const Duration(days: 1));
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next day'),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20),
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
}
