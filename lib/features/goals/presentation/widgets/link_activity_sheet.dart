import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/activity.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../../schedule/presentation/activity_providers.dart';
import '../../domain/goal.dart';
import '../goal_providers.dart';

class LinkActivitySheet extends ConsumerStatefulWidget {
  final Goal goal;

  const LinkActivitySheet({super.key, required this.goal});

  static Future<void> show(BuildContext context, Goal goal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => LinkActivitySheet(goal: goal),
    );
  }

  @override
  ConsumerState<LinkActivitySheet> createState() => _LinkActivitySheetState();
}

class _LinkActivitySheetState extends ConsumerState<LinkActivitySheet> {
  DateTime _selectedDate = TimeUtils.normalizeDate(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final activityRepo = ref.watch(activityRepositoryProvider);
    final goalRepo = ref.watch(goalRepositoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Link Activities', style: AppTypography.headingSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Connect schedule blocks to "${widget.goal.title}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              Text(
                DateFormat('EEEE, MMM d').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<Activity>>(
              stream: activityRepo.watchActivitiesForDate(_selectedDate),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<Activity>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<Activity> activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No activities scheduled on this day.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final Activity act = activities[index];
                        final bool isLinked = widget.goal.linkedActivityIds
                            .contains(act.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLinked
                                  ? AppColors.primary
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: act.category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              act.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${act.startFormatted} - ${act.endFormatted} (${act.durationFormatted})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isLinked
                                    ? Icons.link_off_rounded
                                    : Icons.add_link_rounded,
                                color: isLinked
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                              tooltip: isLinked ? 'Unlink' : 'Link',
                              onPressed: () async {
                                if (isLinked) {
                                  await goalRepo.unlinkActivityFromGoal(
                                    act.id,
                                    widget.goal.id,
                                  );
                                  setState(() {
                                    widget.goal.linkedActivityIds.remove(
                                      act.id,
                                    );
                                  });
                                } else {
                                  await goalRepo.linkActivityToGoal(
                                    act.id,
                                    widget.goal.id,
                                  );
                                  setState(() {
                                    widget.goal.linkedActivityIds.add(act.id);
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
