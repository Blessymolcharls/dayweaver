import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../../../shared/widgets/activity_form_sheet.dart';

class TimelineEmptySlot extends StatelessWidget {
  final UnscheduledGap gap;
  final DateTime date;
  final double height;

  const TimelineEmptySlot({
    super.key,
    required this.gap,
    required this.date,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = height < 40;

    return InkWell(
      onTap: () {
        ActivityFormSheet.show(
          context,
          initialDate: date,
          initialStartMinute: gap.startMinute,
          initialEndMinute: gap.endMinute,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isCompact ? 2 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.categoryUnscheduled.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.7),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: isCompact ? 14 : 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isCompact
                  ? Text(
                      'Free: ${gap.startFormatted} - ${gap.endFormatted} (${gap.durationFormatted})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unscheduled (${gap.durationFormatted})',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${gap.startFormatted} - ${gap.endFormatted} • Tap to schedule',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
