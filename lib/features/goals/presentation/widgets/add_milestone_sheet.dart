import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../domain/goal_milestone.dart';
import '../goal_providers.dart';

class AddMilestoneSheet extends ConsumerStatefulWidget {
  final String goalId;
  final GoalMilestone? initialMilestone;
  final int nextOrderIndex;

  const AddMilestoneSheet({
    super.key,
    required this.goalId,
    this.initialMilestone,
    this.nextOrderIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String goalId,
    GoalMilestone? milestone,
    int nextOrderIndex = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => AddMilestoneSheet(
        goalId: goalId,
        initialMilestone: milestone,
        nextOrderIndex: nextOrderIndex,
      ),
    );
  }

  @override
  ConsumerState<AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends ConsumerState<AddMilestoneSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _targetDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final GoalMilestone? m = widget.initialMilestone;
    _titleController = TextEditingController(text: m?.title ?? '');
    _descController = TextEditingController(text: m?.description ?? '');
    _targetDate = m?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialMilestone != null;

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
                  Text(
                    isEditing ? 'Edit Milestone' : 'Add Milestone',
                    style: AppTypography.headingSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Milestone Title *',
                  hintText: 'e.g. Finish Module 1, Arrays & Pointers',
                ),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter milestone title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Details, deliverables, or checklist items...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined, size: 16),
                      label: Text(
                        _targetDate == null
                            ? 'Set Target Date'
                            : 'Target: ${DateFormat('MMM d').format(_targetDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _targetDate != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      onPressed: _pickTargetDate,
                    ),
                  ),
                  if (_targetDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear Date',
                      onPressed: () => setState(() => _targetDate = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveMilestone,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add Milestone'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTargetDate() async {
    final DateTime now = TimeUtils.normalizeDate(DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _targetDate = TimeUtils.normalizeDate(picked));
    }
  }

  Future<void> _saveMilestone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(goalRepositoryProvider);
    final GoalMilestone? existing = widget.initialMilestone;

    final GoalMilestone milestone = GoalMilestone(
      id: existing?.id ?? const Uuid().v4(),
      goalId: widget.goalId,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      targetDate: _targetDate,
      orderIndex: existing?.orderIndex ?? widget.nextOrderIndex,
      isCompleted: existing?.isCompleted ?? false,
      completedAt: existing?.completedAt,
    );

    try {
      await repo.saveMilestone(milestone);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing != null ? 'Milestone updated.' : 'Milestone added.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
