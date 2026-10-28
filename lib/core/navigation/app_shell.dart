import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import 'destination_placeholder.dart';
import 'nav_destination.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _destinations = const [
    TodayScreen(),
    PlannerScreen(),
    DestinationPlaceholder(destination: NavDestination.goals),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _destinations),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppColors.surfaceElevated,
          indicatorColor: AppColors.surfaceSecondary,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: NavDestination.values.map((dest) {
            return NavigationDestination(
              icon: Icon(dest.icon, color: AppColors.textMuted),
              selectedIcon: Icon(dest.selectedIcon, color: AppColors.primary),
              label: dest.title,
            );
          }).toList(),
        ),
      ),
    );
  }
}
