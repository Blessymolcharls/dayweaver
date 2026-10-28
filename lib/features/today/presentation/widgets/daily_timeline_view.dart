import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/activity.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../../schedule/presentation/activity_providers.dart';
import 'timeline_activity_card.dart';
import 'timeline_empty_slot.dart';
import 'timeline_now_marker.dart';

class DailyTimelineView extends ConsumerStatefulWidget {
  final List<Activity> activities;
  final DateTime date;

  const DailyTimelineView({
    super.key,
    required this.activities,
    required this.date,
  });

  @override
  ConsumerState<DailyTimelineView> createState() => _DailyTimelineViewState();
}

class _DailyTimelineViewState extends ConsumerState<DailyTimelineView> {
  late final ScrollController _scrollController;
  static const double _hourHeight = 64.0;
  static const double _minuteScale = _hourHeight / 60.0; // dp per minute
  static const double _totalTimelineHeight = 24 * _hourHeight; // 1,536 dp
  static const double _timeRailWidth = 54.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToInitialPosition(),
    );
  }

  @override
  void didUpdateWidget(covariant DailyTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.date.isAtSameMomentAs(widget.date)) {
      _scrollToInitialPosition();
    }
  }

  void _scrollToInitialPosition() {
    if (!_scrollController.hasClients) return;

    final today = TimeUtils.normalizeDate(DateTime.now());
    final isToday = widget.date.isAtSameMomentAs(today);

    double targetOffset = 0;
    if (isToday) {
      final now = DateTime.now();
      final nowMinute = now.hour * 60 + now.minute;
      targetOffset = (nowMinute * _minuteScale) - 180;
    } else if (widget.activities.isNotEmpty) {
      // Scroll to first activity minus 1 hour
      final firstStart = widget.activities.first.startMinute;
      targetOffset = (firstStart * _minuteScale) - 60;
    } else {
      // Default to 07:00 morning
      targetOffset = (7 * 60 * _minuteScale) - 60;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clamped = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = TimeUtils.normalizeDate(DateTime.now());
    final isToday = widget.date.isAtSameMomentAs(today);
    final currentMinuteAsync = ref.watch(currentMinuteProvider);
    final currentMinute =
        currentMinuteAsync.valueOrNull ??
        (DateTime.now().hour * 60 + DateTime.now().minute);

    // Compute unscheduled gaps for the day
    final gaps = TimeUtils.calculateUnscheduledGaps(widget.activities);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Stack(
        children: [
          // Background hour grid lines and labels
          SizedBox(
            height: _totalTimelineHeight + 20,
            child: Column(
              children: List.generate(25, (hour) {
                final minute = hour * 60;
                final isHour24 = hour == 24;
                return SizedBox(
                  height: isHour24 ? 20 : _hourHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hour label
                      SizedBox(
                        width: _timeRailWidth,
                        child: Text(
                          TimeUtils.formatMinutes(minute),
                          style: AppTypography.timeLabel.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Horizontal divider line
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 1,
                          color: AppColors.divider.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Content Rail (Activities & Free Gaps)
          Positioned(
            top: 8,
            left: _timeRailWidth + 8,
            right: 0,
            height: _totalTimelineHeight,
            child: Stack(
              children: [
                // Render Unscheduled Free Gaps
                ...gaps.map((gap) {
                  final top = gap.startMinute * _minuteScale;
                  final height = (gap.durationMinutes * _minuteScale) - 2;
                  if (height <= 2) return const SizedBox.shrink();

                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    height: height,
                    child: TimelineEmptySlot(
                      gap: gap,
                      date: widget.date,
                      height: height,
                    ),
                  );
                }),

                // Render Scheduled Activities
                ...widget.activities.map((activity) {
                  final top = activity.startMinute * _minuteScale;
                  final height = (activity.durationMinutes * _minuteScale) - 2;
                  final renderHeight = height.clamp(24.0, double.infinity);

                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    height: renderHeight,
                    child: TimelineActivityCard(
                      activity: activity,
                      height: renderHeight,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Current Time Marker (Shown only for today)
          if (isToday)
            TimelineNowMarker(
              currentMinute: currentMinute,
              topOffset: (currentMinute * _minuteScale) + 8,
            ),
        ],
      ),
    );
  }
}
