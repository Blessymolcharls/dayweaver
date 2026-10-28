import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../../schedule/presentation/activity_providers.dart';
import '../../../schedule/presentation/routine_templates_screen.dart';
import '../../../schedule/presentation/widgets/copy_schedule_sheet.dart';

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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_getGreeting(), style: AppTypography.headingMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isToday)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).state = today;
                      },
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: const Text('Back to Today'),
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
                    tooltip: 'Schedule options',
                    itemBuilder: (context) => [
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
                    ],
                    onSelected: (val) {
                      if (val == 'routines') {
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
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date navigation row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous day',
                  color: AppColors.textPrimary,
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = selectedDate
                        .subtract(const Duration(days: 1));
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        ref.read(selectedDateProvider.notifier).state =
                            TimeUtils.normalizeDate(picked);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('EEEE').format(selectedDate),
                          style: AppTypography.titleMedium.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(selectedDate),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next day',
                  color: AppColors.textPrimary,
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = selectedDate
                        .add(const Duration(days: 1));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
