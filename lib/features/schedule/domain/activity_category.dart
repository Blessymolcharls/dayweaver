import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum ActivityCategory {
  college('College', Icons.school_outlined, AppColors.categoryCollege),
  coding('Coding', Icons.code_rounded, AppColors.categoryCoding),
  personal(
    'Personal Work',
    Icons.work_outline_rounded,
    AppColors.categoryPersonal,
  ),
  meals('Meals', Icons.restaurant_outlined, AppColors.categoryMeals),
  rest('Rest & Wellness', Icons.spa_outlined, AppColors.categoryRest),
  sleep('Sleep', Icons.bedtime_outlined, AppColors.categorySleep);

  const ActivityCategory(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;

  Color get surfaceColor => color.withValues(alpha: 0.12);
  Color get borderColor => color.withValues(alpha: 0.35);

  static ActivityCategory fromString(String val) {
    return ActivityCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ActivityCategory.personal,
    );
  }
}
