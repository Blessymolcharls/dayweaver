import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../schedule/presentation/recurring_activities_screen.dart';
import '../../schedule/presentation/routine_templates_screen.dart';
import '../../today/presentation/daily_review_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoadingPermission = false;
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final NotificationService service = ref.read(notificationServiceProvider);
    final bool isEnabled = await service.areNotificationsEnabled();
    if (mounted) {
      setState(() => _notificationsEnabled = isEnabled);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoadingPermission = true);
    final NotificationService service = ref.read(notificationServiceProvider);
    final bool granted = await service.requestPermissions();
    if (mounted) {
      setState(() {
        _notificationsEnabled = granted;
        _isLoadingPermission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notifications enabled successfully.'
                : 'Notification permission was denied. You can enable it in Android System Settings.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Notification Permissions Card
          _buildNotificationsCard(),
          const SizedBox(height: 20),

          // Planning & Routine Tools Card
          _buildPlanningToolsCard(),
          const SizedBox(height: 20),

          // Reliability & Power Management Guidance
          _buildReliabilityCard(),
          const SizedBox(height: 20),

          // About Dayweaver
          _buildAboutCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final Color statusColor = (_notificationsEnabled == true)
        ? AppColors.secondary
        : AppColors.primary;
    final String statusText = (_notificationsEnabled == true)
        ? 'Enabled'
        : (_notificationsEnabled == false
              ? 'Disabled / Denied'
              : 'Checking...');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications & Reminders',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Permission Status',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Android 13+ requires explicit notification permissions so Dayweaver can alert you before scheduled activities start.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (_notificationsEnabled != true)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoadingPermission ? null : _requestPermission,
                icon: const Icon(Icons.security_update_good_rounded),
                label: _isLoadingPermission
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Grant Notification Permission'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanningToolsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planning & Tools', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.repeat_rounded, color: AppColors.primary),
            title: const Text('Recurring Activities'),
            subtitle: const Text(
              'Manage daily, weekday, or custom repeating schedules',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const RecurringActivitiesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.secondary,
            ),
            title: const Text('Daily Review'),
            subtitle: const Text('Reflect on accomplishments and plan ahead'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const DailyReviewScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.dashboard_customize_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Routine Templates'),
            subtitle: const Text('View and create reusable daily routines'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const RoutineTemplatesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReliabilityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text('Scheduling Reliability', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Least-Privileged Scheduling: Dayweaver uses standard Android battery-conscious scheduled reminders without aggressive wake locks.\n'
            '• Reboot Recovery: Dayweaver automatically rebuilds all pending reminders from SQLite whenever the device restarts or the app launches.\n'
            '• Battery Optimization: On some Android devices (e.g., Xiaomi, Samsung), aggressive power management may delay reminders. Allowing unrestricted background activity in Android App Info ensures punctual delivery.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Dayweaver', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Dayweaver is a calm, aesthetic, offline-first 24-hour schedule planner designed to help you balance college, coding projects, meals, rest, and sleep.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
              Text(
                '1.0.0 (Milestone 3)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
