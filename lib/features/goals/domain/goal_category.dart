import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum GoalCategory {
  academics('Academics', Icons.school_outlined, AppColors.categoryCollege),
  coding('Coding & Skills', Icons.code_rounded, AppColors.categoryCoding),
  projects('Projects', Icons.folder_special_outlined, AppColors.primary),
  career(
    'Career & Placements',
    Icons.work_outline_rounded,
    AppColors.categoryPersonal,
  ),
  health('Health & Wellbeing', Icons.spa_outlined, AppColors.categoryRest),
  personal(
    'Personal Development',
    Icons.auto_awesome_outlined,
    AppColors.secondary,
  ),
  custom('Custom', Icons.stars_outlined, AppColors.warning);

  const GoalCategory(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;

  Color get surfaceColor => color.withValues(alpha: 0.12);
  Color get borderColor => color.withValues(alpha: 0.35);

  static GoalCategory fromString(String val) {
    return GoalCategory.values.firstWhere(
      (GoalCategory e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GoalCategory.personal,
    );
  }
}
