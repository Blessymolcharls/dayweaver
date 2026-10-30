import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/goal.dart';
import '../../domain/goal_status.dart';
import '../goal_providers.dart';

class RecordProgressSheet extends ConsumerStatefulWidget {
  final Goal goal;

  const RecordProgressSheet({super.key, required this.goal});

  static Future<void> show(BuildContext context, Goal goal) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => RecordProgressSheet(goal: goal),
    );
  }

  @override
  ConsumerState<RecordProgressSheet> createState() =>
      _RecordProgressSheetState();
}

class _RecordProgressSheetState extends ConsumerState<RecordProgressSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isIncremental = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _previewResultingValue {
    final double? entered = double.tryParse(_amountController.text.trim());
    if (entered == null) return widget.goal.currentValue;
    if (_isIncremental) {
      return (widget.goal.currentValue + entered).clamp(0.0, double.infinity);
    } else {
      return entered.clamp(0.0, double.infinity);
    }
  }

  double get _previewProgressRatio {
    if (widget.goal.targetValue <= 0) return 0.0;
    return (_previewResultingValue / widget.goal.targetValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Goal goal = widget.goal;
    final double previewVal = _previewResultingValue;
    final int previewPercent = (_previewProgressRatio * 100).round();
    final bool willReachTarget = previewVal >= goal.targetValue;

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                        Text(
                          'Update Progress',
                          style: AppTypography.headingSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
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

              // Mode toggle: Incremental vs Absolute
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncremental = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isIncremental
                                ? AppColors.surfaceElevated
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _isIncremental
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Add Progress (+)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isIncremental
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: _isIncremental
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncremental = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isIncremental
                                ? AppColors.surfaceElevated
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_isIncremental
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Set Total Value (=)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_isIncremental
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: !_isIncremental
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Value input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _isIncremental
                      ? 'Amount to add (${goal.unit}) *'
                      : 'New total value (${goal.unit}) *',
                  hintText: _isIncremental ? 'e.g. 2.0' : 'e.g. 15.0',
                  suffixText: goal.unit,
                ),
                onChanged: (_) => setState(() {}),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  final double? num = double.tryParse(val.trim());
                  if (num == null) {
                    return 'Enter a valid number';
                  }
                  if (_isIncremental && num <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (!_isIncremental && num < 0) {
                    return 'Value cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Optional Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Optional note / reflection',
                  hintText: 'e.g. Completed DP problem set, 2 chapters read',
                ),
              ),
              const SizedBox(height: 16),

              // Preview card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resulting Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$previewPercent%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: willReachTarget
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _previewProgressRatio,
                        minHeight: 6,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          willReachTarget
                              ? AppColors.secondary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${previewVal.toStringAsFixed(1)} of ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (willReachTarget) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.celebration_rounded,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Target achieved! This goal can now be completed.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitProgress,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Progress Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProgress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final double amount = double.parse(_amountController.text.trim());
    final String? note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final repo = ref.read(goalRepositoryProvider);

    try {
      await repo.recordProgressUpdate(
        goalId: widget.goal.id,
        changeAmount: amount,
        isIncremental: _isIncremental,
        note: note,
      );

      final double resulting = _previewResultingValue;
      if (resulting >= widget.goal.targetValue &&
          widget.goal.status == GoalStatus.active &&
          mounted) {
        // Offer quick complete dialog
        _showGoalCompletionPrompt(context, repo);
      } else if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showGoalCompletionPrompt(BuildContext context, dynamic repo) {
    Navigator.pop(context); // Close sheet
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Target Reached! 🎉'),
        content: Text(
          'You have reached your target for "${widget.goal.title}". Would you like to mark this goal as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Active'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () {
              repo.updateGoalStatus(widget.goal.id, GoalStatus.completed);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Goal "${widget.goal.title}" marked completed!',
                  ),
                ),
              );
            },
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
  }
}
