import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum ActivityPriority {
  low('Low', AppColors.textMuted),
  medium('Medium', AppColors.warning),
  high('High', AppColors.error);

  const ActivityPriority(this.displayName, this.color);

  final String displayName;
  final Color color;

  static ActivityPriority fromString(String val) {
    return ActivityPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ActivityPriority.medium,
    );
  }
}
