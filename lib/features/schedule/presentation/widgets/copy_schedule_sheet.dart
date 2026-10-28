import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/conflict_strategy.dart';
import '../../domain/time_utils.dart';
import '../activity_providers.dart';

class CopyScheduleSheet extends ConsumerStatefulWidget {
  final DateTime initialSourceDate;
  final DateTime? initialTargetDate;

  const CopyScheduleSheet({
    super.key,
    required this.initialSourceDate,
    this.initialTargetDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DateTime initialSourceDate,
    DateTime? initialTargetDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CopyScheduleSheet(
        initialSourceDate: initialSourceDate,
        initialTargetDate: initialTargetDate,
      ),
    );
  }

  @override
  ConsumerState<CopyScheduleSheet> createState() => _CopyScheduleSheetState();
}

class _CopyScheduleSheetState extends ConsumerState<CopyScheduleSheet> {
  late DateTime _sourceDate;
  late DateTime _targetDate;
  ConflictStrategy _strategy = ConflictStrategy.skipConflicts;
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _sourceDate = widget.initialSourceDate;
    _targetDate =
        widget.initialTargetDate ??
        widget.initialSourceDate.add(const Duration(days: 1));
  }

  Future<void> _pickSourceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sourceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _sourceDate = TimeUtils.normalizeDate(picked));
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _targetDate = TimeUtils.normalizeDate(picked));
    }
  }

  Future<void> _copy() async {
    if (_sourceDate.isAtSameMomentAs(_targetDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Source and destination dates must be different.'),
        ),
      );
      return;
    }

    setState(() => _isCopying = true);

    final repo = ref.read(activityRepositoryProvider);
    final result = await repo.copySchedule(
      fromDate: _sourceDate,
      toDate: _targetDate,
      conflictStrategy: _strategy,
    );

    if (!mounted) return;
    setState(() => _isCopying = false);

    if (result.success) {
      Navigator.pop(context, true);
      final msg = result.skippedCount > 0
          ? 'Copied schedule: ${result.addedCount} activities copied, ${result.skippedCount} skipped due to conflicts.'
          : 'Copied ${result.addedCount} activities to ${DateFormat('MMM d').format(_targetDate)}.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            msg,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            result.errorMessage ?? 'Failed to copy schedule.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Copy Schedule', style: AppTypography.headingMedium),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Duplicate an entire day’s activities to another date.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Source Date
          Text('From (Source Date)', style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickSourceDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_sourceDate),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Destination Date
          Text('To (Destination Date)', style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickTargetDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_targetDate),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Conflict Handling Choice
          Text('Conflict Handling', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          ...ConflictStrategy.values.map((strat) {
            final isSelected = strat == _strategy;
            return InkWell(
              onTap: () => setState(() => _strategy = strat),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strat.displayName,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            strat.description,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Copy Button
          ElevatedButton(
            onPressed: _isCopying ? null : _copy,
            child: _isCopying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Copy to ${DateFormat('MMM d').format(_targetDate)}'),
          ),
        ],
      ),
    );
  }
}
