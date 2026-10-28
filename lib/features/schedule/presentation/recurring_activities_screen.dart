import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../data/activity_repository.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/recurrence_rule.dart';
import '../domain/time_utils.dart';
import 'activity_providers.dart';

class RecurringActivitiesScreen extends ConsumerWidget {
  const RecurringActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecurrenceRule>> rulesAsync = ref.watch(
      recurrenceRulesStreamProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recurring Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Recurring Rule',
            onPressed: () => _showAddRuleSheet(context, ref),
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (List<RecurrenceRule> rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Recurring Activities',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Automate daily or weekday routines like coding practice, college lectures, or evening walks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddRuleSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Recurring Rule'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final RecurrenceRule rule = rules[index];
              return _RecurrenceRuleCard(rule: rule);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const _AddRecurrenceRuleSheet(),
    );
  }
}

class _RecurrenceRuleCard extends ConsumerWidget {
  final RecurrenceRule rule;

  const _RecurrenceRuleCard({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActivityRepository repo = ref.watch(activityRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: rule.category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: rule.isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (bool val) {
                  repo.toggleRecurrenceRuleEnabled(rule.id, val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${rule.startFormatted} - ${rule.endFormatted} (${rule.durationFormatted})',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                rule.category.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: rule.category.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.repeat_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                rule.recurrenceDescription,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (rule.reminderOffsetMinutes != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  rule.reminderOffsetMinutes == 0
                      ? 'Reminder at start time'
                      : 'Reminder ${rule.reminderOffsetMinutes}m before',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Recurrence Rule'),
        content: Text(
          'Are you sure you want to delete "${rule.title}"? Existing scheduled occurrences will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(activityRepositoryProvider)
                  .deleteRecurrenceRule(rule.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddRecurrenceRuleSheet extends ConsumerStatefulWidget {
  const _AddRecurrenceRuleSheet();

  @override
  ConsumerState<_AddRecurrenceRuleSheet> createState() =>
      _AddRecurrenceRuleSheetState();
}

class _AddRecurrenceRuleSheetState
    extends ConsumerState<_AddRecurrenceRuleSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  ActivityCategory _category = ActivityCategory.coding;
  final ActivityPriority _priority = ActivityPriority.medium;
  RecurrenceType _recurrenceType = RecurrenceType.weekdays;
  List<int> _selectedDays = [1, 2, 3, 4, 5];

  int _startMinute = 9 * 60; // 09:00
  int _endMinute = 10 * 60; // 10:00
  int? _reminderOffset = 15;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'New Recurring Activity',
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
                  labelText: 'Title *',
                  hintText: 'e.g. Daily Coding, College Lecture',
                ),
                validator: (String? val) => (val == null || val.trim().isEmpty)
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ActivityCategory.values.map((ActivityCategory cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ActivityCategory? cat) =>
                    setState(() => _category = cat!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text(
                        'Start: ${TimeUtils.formatMinutes(_startMinute)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text(
                        'End: ${TimeUtils.formatMinutes(_endMinute)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurrenceType>(
                initialValue: _recurrenceType,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: const [
                  DropdownMenuItem(
                    value: RecurrenceType.daily,
                    child: Text('Every day'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.weekdays,
                    child: Text('Every weekday (Mon - Fri)'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.custom,
                    child: Text('Custom days'),
                  ),
                ],
                onChanged: (RecurrenceType? val) {
                  setState(() {
                    _recurrenceType = val!;
                    if (_recurrenceType == RecurrenceType.daily) {
                      _selectedDays = [1, 2, 3, 4, 5, 6, 7];
                    } else if (_recurrenceType == RecurrenceType.weekdays) {
                      _selectedDays = [1, 2, 3, 4, 5];
                    }
                  });
                },
              ),
              if (_recurrenceType == RecurrenceType.custom) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (int index) {
                    final int dayNum = index + 1;
                    const List<String> names = [
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ];
                    final bool isSelected = _selectedDays.contains(dayNum);
                    return FilterChip(
                      label: Text(names[index]),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(dayNum);
                          } else {
                            _selectedDays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _reminderOffset,
                decoration: const InputDecoration(labelText: 'Reminder'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('No reminder')),
                  DropdownMenuItem(value: 0, child: Text('At start time')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                ],
                onChanged: (int? val) => setState(() => _reminderOffset = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveRule,
                  child: const Text('Save Recurrence Rule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final int currentMinute = isStart ? _startMinute : _endMinute;
    final TimeOfDay initial = TimeOfDay(
      hour: currentMinute ~/ 60,
      minute: currentMinute % 60,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        final int newMin = picked.hour * 60 + picked.minute;
        if (isStart) {
          _startMinute = newMin;
          if (_endMinute <= _startMinute) {
            _endMinute = (_startMinute + 60).clamp(0, 1440);
          }
        } else {
          if (newMin > _startMinute) {
            _endMinute = newMin;
          }
        }
      });
    }
  }

  void _saveRule() {
    if (!_formKey.currentState!.validate()) return;

    if (_recurrenceType == RecurrenceType.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    final RecurrenceRule rule = RecurrenceRule(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _category,
      startMinute: _startMinute,
      endMinute: _endMinute,
      recurrenceType: _recurrenceType,
      daysOfWeek: _selectedDays,
      startDate: TimeUtils.normalizeDate(DateTime.now()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      priority: _priority,
      reminderOffsetMinutes: _reminderOffset,
    );

    ref.read(activityRepositoryProvider).saveRecurrenceRule(rule);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved recurring activity "${rule.title}".')),
    );
  }
}
