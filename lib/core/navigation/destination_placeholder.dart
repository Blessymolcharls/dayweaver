import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'nav_destination.dart';

class DestinationPlaceholder extends StatelessWidget {
  final NavDestination destination;

  const DestinationPlaceholder({super.key, required this.destination});

  String get _description {
    switch (destination) {
      case NavDestination.planner:
        return 'Multi-day weekly templates, routine weavers, and recurring batch scheduling will arrive in Milestone 2.';
      case NavDestination.goals:
        return 'Semester objectives, assignment milestones, and skill target tracking are coming soon.';
      case NavDestination.insights:
        return 'Analytics on study time vs. rest balance, deep work distribution, and schedule adherence will be woven here.';
      case NavDestination.today:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  destination.selectedIcon,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(destination.title, style: AppTypography.headingMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Planned for Next Milestone',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
