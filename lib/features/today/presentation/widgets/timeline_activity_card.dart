import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/activity.dart';
import '../../../schedule/presentation/activity_providers.dart';
import '../../../../shared/widgets/activity_form_sheet.dart';

class TimelineActivityCard extends ConsumerWidget {
  final Activity activity;
  final double height;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = activity.category;
    final isCompact = height < 50;
    final isUltraCompact = height < 34;

    return InkWell(
      onTap: () {
        ActivityFormSheet.show(
          context,
          activityToEdit: activity,
          initialDate: activity.date,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isUltraCompact ? 2 : (isCompact ? 4 : 8),
        ),
        decoration: BoxDecoration(
          color: activity.isCompleted
              ? AppColors.surfaceElevated.withValues(alpha: 0.8)
              : category.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activity.isCompleted
                ? AppColors.borderSubtle
                : category.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: category.color.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left color pill / bar
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: isUltraCompact
                  ? Row(
                      children: [
                        Text(
                          '${activity.startFormatted} - ${activity.endFormatted}',
                          style: AppTypography.timeLabel.copyWith(fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: activity.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${activity.startFormatted} - ${activity.endFormatted}',
                              style: AppTypography.timeLabel.copyWith(
                                color: activity.isCompleted
                                    ? AppColors.textMuted
                                    : category.color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.displayName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: category.color,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            activity.title,
                            maxLines: isCompact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              decoration: activity.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: activity.isCompleted
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!isCompact &&
                            activity.notes != null &&
                            activity.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              activity.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            // Completion toggle
            if (!isUltraCompact)
              InkWell(
                onTap: () {
                  ref
                      .read(activityRepositoryProvider)
                      .toggleCompletion(activity.id, !activity.isCompleted);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    activity.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: activity.isCompleted
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
