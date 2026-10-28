import 'package:flutter/material.dart';

enum NavDestination {
  today(
    title: 'Today',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
  ),
  planner(
    title: 'Planner',
    icon: Icons.view_week_outlined,
    selectedIcon: Icons.view_week_rounded,
  ),
  goals(
    title: 'Goals',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
  ),
  insights(
    title: 'Insights',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  );

  const NavDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
}
