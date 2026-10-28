import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/time_utils.dart';

class TimelineNowMarker extends StatelessWidget {
  final int currentMinute;
  final double topOffset;

  const TimelineNowMarker({
    super.key,
    required this.currentMinute,
    required this.topOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset - 9, // Centered on the minute line
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pill with current time and NOW label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.nowIndicator,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.nowIndicatorGlow,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '${TimeUtils.formatMinutes(currentMinute)} NOW',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Horizontal indicator line
            Expanded(
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  color: AppColors.nowIndicator,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.nowIndicatorGlow,
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
