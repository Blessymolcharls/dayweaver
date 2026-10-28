import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/conflict_strategy.dart';
import '../../domain/routine_template.dart';
import '../../domain/time_utils.dart';
import '../activity_providers.dart';

class ApplyRoutineSheet extends ConsumerStatefulWidget {
  final RoutineTemplate template;
  final DateTime initialDate;

  const ApplyRoutineSheet({
    super.key,
    required this.template,
    required this.initialDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RoutineTemplate template,
    required DateTime initialDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          ApplyRoutineSheet(template: template, initialDate: initialDate),
    );
  }

  @override
  ConsumerState<ApplyRoutineSheet> createState() => _ApplyRoutineSheetState();
}

class _ApplyRoutineSheetState extends ConsumerState<ApplyRoutineSheet> {
  late DateTime _selectedDate;
  ConflictStrategy _strategy = ConflictStrategy.skipConflicts;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = TimeUtils.normalizeDate(picked));
    }
  }

  Future<void> _apply() async {
    setState(() => _isApplying = true);

    final repo = ref.read(activityRepositoryProvider);
    final result = await repo.applyTemplateToDate(
      templateId: widget.template.id,
      date: _selectedDate,
      conflictStrategy: _strategy,
    );

    if (!mounted) return;
    setState(() => _isApplying = false);

    if (result.success) {
      Navigator.pop(context, true);
      final msg = result.skippedCount > 0
          ? 'Applied routine: ${result.addedCount} scheduled, ${result.skippedCount} skipped due to conflicts.'
          : 'Applied routine: ${result.addedCount} activities scheduled for ${DateFormat('MMM d').format(_selectedDate)}.';

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
            result.errorMessage ?? 'Failed to apply routine.',
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
              Text('Apply Routine', style: AppTypography.headingMedium),
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
            'Apply "${widget.template.name}" (${widget.template.blockCount} activities • ${widget.template.totalDurationFormatted}) to your schedule.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Target Date Selector
          Text('Destination Date', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
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
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
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

          // Apply Button
          ElevatedButton(
            onPressed: _isApplying ? null : _apply,
            child: _isApplying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Apply to ${DateFormat('MMM d').format(_selectedDate)}'),
          ),
        ],
      ),
    );
  }
}
