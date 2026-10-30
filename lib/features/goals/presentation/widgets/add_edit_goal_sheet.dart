import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../schedule/domain/activity_priority.dart';
import '../../../schedule/domain/time_utils.dart';
import '../../domain/goal.dart';
import '../../domain/goal_category.dart';
import '../../domain/goal_status.dart';
import '../goal_providers.dart';

class AddEditGoalSheet extends ConsumerStatefulWidget {
  final Goal? initialGoal;

  const AddEditGoalSheet({super.key, this.initialGoal});

  static Future<void> show(BuildContext context, {Goal? goal}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => AddEditGoalSheet(initialGoal: goal),
    );
  }

  @override
  ConsumerState<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends ConsumerState<AddEditGoalSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;

  late GoalCategory _category;
  late ActivityPriority _priority;
  late DateTime _startDate;
  DateTime? _targetDate;
  bool _isSaving = false;

  final List<String> _commonUnits = [
    'hours',
    'problems',
    'chapters',
    'days',
    'milestones',
    'sessions',
    'tasks',
  ];

  @override
  void initState() {
    super.initState();
    final Goal? g = widget.initialGoal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _targetController = TextEditingController(
      text: g != null
          ? (g.targetValue == g.targetValue.roundToDouble()
                ? g.targetValue.toInt().toString()
                : g.targetValue.toString())
          : '',
    );
    _unitController = TextEditingController(text: g?.unit ?? 'hours');
    _notesController = TextEditingController(text: g?.notes ?? '');

    _category = g?.category ?? GoalCategory.coding;
    _priority = g?.priority ?? ActivityPriority.medium;
    _startDate = g?.startDate ?? TimeUtils.normalizeDate(DateTime.now());
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialGoal != null;

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
                    isEditing ? 'Edit Goal' : 'New Goal',
                    style: AppTypography.headingSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title *',
                  hintText: 'e.g. Master 50 LeetCode Problems',
                ),
                validator: (String? val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is the purpose or context of this goal?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category and Priority Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<GoalCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: GoalCategory.values.map((GoalCategory cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.displayName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (GoalCategory? cat) =>
                          setState(() => _category = cat!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ActivityPriority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: ActivityPriority.values.map((ActivityPriority p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.displayName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (ActivityPriority? p) =>
                          setState(() => _priority = p!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target Value & Unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Target *',
                        hintText: 'e.g. 50',
                      ),
                      validator: (String? val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter target';
                        }
                        final double? num = double.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit *',
                        hintText: 'e.g. hours, problems',
                      ),
                      validator: (String? val) =>
                          (val == null || val.trim().isEmpty)
                          ? 'Enter unit'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Common units chips
              Wrap(
                spacing: 6,
                children: _commonUnits.map((String u) {
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    label: Text(u, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() => _unitController.text = u);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        'Start: ${DateFormat('MMM d').format(_startDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_available_rounded, size: 16),
                      label: Text(
                        _targetDate == null
                            ? 'No Deadline'
                            : 'Due: ${DateFormat('MMM d').format(_targetDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _targetDate != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      onPressed: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              if (_targetDate != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => setState(() => _targetDate = null),
                    child: const Text(
                      'Clear Deadline',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Optional Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes & Milestones Plan (Optional)',
                  hintText: 'Action plan, recommended resources, milestones...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveGoal,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial = isStart ? _startDate : (_targetDate ?? _startDate);
    final DateTime first = isStart
        ? DateTime(2020)
        : TimeUtils.normalizeDate(_startDate);
    final DateTime last = DateTime(2035);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = TimeUtils.normalizeDate(picked);
          if (_targetDate != null && _targetDate!.isBefore(_startDate)) {
            _targetDate = _startDate;
          }
        } else {
          _targetDate = TimeUtils.normalizeDate(picked);
        }
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_targetDate != null && _targetDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline cannot be before start date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(goalRepositoryProvider);

    final double target = double.parse(_targetController.text.trim());
    final Goal? existing = widget.initialGoal;

    final Goal goalToSave = Goal(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _category,
      status: existing?.status ?? GoalStatus.active,
      priority: _priority,
      targetValue: target,
      currentValue: existing?.currentValue ?? 0.0,
      unit: _unitController.text.trim(),
      startDate: _startDate,
      targetDate: _targetDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      milestones: existing?.milestones ?? const [],
      linkedActivityIds: existing?.linkedActivityIds ?? const [],
    );

    try {
      await repo.saveGoal(goalToSave);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing != null
                  ? 'Goal "${goalToSave.title}" updated.'
                  : 'Goal "${goalToSave.title}" created.',
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
