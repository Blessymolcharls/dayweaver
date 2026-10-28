import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../features/schedule/domain/activity.dart';
import '../../features/schedule/domain/activity_category.dart';
import '../../features/schedule/domain/activity_priority.dart';
import '../../features/schedule/domain/time_utils.dart';
import '../../features/schedule/presentation/activity_providers.dart';

class ActivityFormSheet extends ConsumerStatefulWidget {
  final Activity? activityToEdit;
  final DateTime initialDate;
  final int? initialStartMinute;
  final int? initialEndMinute;

  const ActivityFormSheet({
    super.key,
    this.activityToEdit,
    required this.initialDate,
    this.initialStartMinute,
    this.initialEndMinute,
  });

  static Future<void> show(
    BuildContext context, {
    Activity? activityToEdit,
    required DateTime initialDate,
    int? initialStartMinute,
    int? initialEndMinute,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ActivityFormSheet(
        activityToEdit: activityToEdit,
        initialDate: initialDate,
        initialStartMinute: initialStartMinute,
        initialEndMinute: initialEndMinute,
      ),
    );
  }

  @override
  ConsumerState<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends ConsumerState<ActivityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late ActivityCategory _category;
  late ActivityPriority _priority;
  late int _startMinute;
  late int _endMinute;
  int? _reminderOffset;
  late bool _isCompleted;
  bool _isSaving = false;
  String? _overlapError;

  @override
  void initState() {
    super.initState();
    final edit = widget.activityToEdit;
    if (edit != null) {
      _titleController = TextEditingController(text: edit.title);
      _notesController = TextEditingController(text: edit.notes ?? '');
      _selectedDate = edit.date;
      _category = edit.category;
      _priority = edit.priority;
      _startMinute = edit.startMinute;
      _endMinute = edit.endMinute;
      _reminderOffset = edit.reminderOffsetMinutes;
      _isCompleted = edit.isCompleted;
    } else {
      _titleController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDate = widget.initialDate;
      _category = ActivityCategory.college;
      _priority = ActivityPriority.medium;
      _startMinute = widget.initialStartMinute ?? 540; // 09:00 default
      _endMinute = widget.initialEndMinute ?? 600; // 10:00 default
      _reminderOffset = null;
      _isCompleted = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = TimeUtils.normalizeDate(picked);
        _overlapError = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final initial = TimeOfDay(
      hour: _startMinute ~/ 60,
      minute: _startMinute % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surfaceElevated,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final newStart = TimeUtils.timeOfDayToMinutes(picked);
      setState(() {
        _startMinute = newStart;
        if (_endMinute <= _startMinute) {
          // Auto adjust end time to start + 60 mins (capped at 1440)
          _endMinute = (_startMinute + 60).clamp(0, TimeUtils.minutesPerDay);
        }
        _overlapError = null;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final initialHour = _endMinute >= TimeUtils.minutesPerDay
        ? 23
        : _endMinute ~/ 60;
    final initialMinute = _endMinute >= TimeUtils.minutesPerDay
        ? 59
        : _endMinute % 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'Select End Time (or tap 24:00 below)',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surfaceElevated,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final newEnd = TimeUtils.timeOfDayToMinutes(picked);
      setState(() {
        _endMinute = newEnd;
        _overlapError = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final timeValidationError = TimeUtils.validateTimeRange(
      _startMinute,
      _endMinute,
    );
    if (timeValidationError != null) {
      setState(() {
        _overlapError = timeValidationError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _overlapError = null;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      final existingOnDate = await repo.getActivitiesForDate(_selectedDate);

      final overlapCheck = TimeUtils.checkOverlap(
        startMinute: _startMinute,
        endMinute: _endMinute,
        existingActivities: existingOnDate,
        excludeActivityId: widget.activityToEdit?.id,
      );

      if (overlapCheck.hasOverlap) {
        setState(() {
          _isSaving = false;
          _overlapError =
              'Overlaps with "${overlapCheck.conflictingTitle}". Adjust start or end time.';
        });
        return;
      }

      final activity = Activity(
        id: widget.activityToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _category,
        date: _selectedDate,
        startMinute: _startMinute,
        endMinute: _endMinute,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isCompleted: _isCompleted,
        priority: _priority,
        reminderOffsetMinutes: _reminderOffset,
        createdAt: widget.activityToEdit?.createdAt,
      );

      await repo.saveActivity(activity);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              widget.activityToEdit != null
                  ? 'Activity updated'
                  : 'Activity scheduled',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _overlapError = 'Failed to save: $e';
      });
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Activity', style: AppTypography.headingSmall),
        content: Text(
          'Are you sure you want to delete "${widget.activityToEdit!.title}"?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await ref
          .read(activityRepositoryProvider)
          .deleteActivity(widget.activityToEdit!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activityToEdit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Activity' : 'New Activity',
                    style: AppTypography.headingMedium,
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      tooltip: 'Delete',
                      onPressed: _confirmDelete,
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Overlap or validation error banner
              if (_overlapError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _overlapError!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title input
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Activity Title *',
                  hintText: 'e.g., Algorithms Lecture, LeetCode practice',
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category selector
              Text('Category', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.displayName),
                    selected: isSelected,
                    selectedColor: cat.color,
                    backgroundColor: AppColors.surfaceSecondary,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? cat.color : AppColors.borderSubtle,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date and Time Row
              Text('Date & Schedule', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
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
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
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
              const SizedBox(height: 12),

              // Time selector cards
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('START TIME', style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            Text(
                              TimeUtils.formatMinutes(_startMinute),
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'END TIME',
                                    style: AppTypography.labelSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_endMinute < TimeUtils.minutesPerDay)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _endMinute = TimeUtils.minutesPerDay;
                                        _overlapError = null;
                                      });
                                    },
                                    child: Text(
                                      '24:00',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              TimeUtils.formatMinutes(_endMinute),
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Duration: ${TimeUtils.formatDuration((_endMinute - _startMinute).clamp(0, TimeUtils.minutesPerDay))}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Priority & Status Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priority', style: AppTypography.labelLarge),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ActivityPriority>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: ActivityPriority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: p.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.displayName,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder (Offline)',
                          style: AppTypography.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          initialValue: _reminderOffset,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('None')),
                            DropdownMenuItem(
                              value: 5,
                              child: Text('5 min before'),
                            ),
                            DropdownMenuItem(
                              value: 10,
                              child: Text('10 min before'),
                            ),
                            DropdownMenuItem(
                              value: 15,
                              child: Text('15 min before'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('30 min before'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _reminderOffset = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Optional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add details, location, links, or sub-tasks...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Completed Toggle (if editing)
              if (isEditing) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.success,
                  title: Text(
                    'Mark as completed',
                    style: AppTypography.titleMedium,
                  ),
                  subtitle: Text(
                    'Counts towards today’s accomplished hours',
                    style: AppTypography.bodySmall,
                  ),
                  value: _isCompleted,
                  onChanged: (val) =>
                      setState(() => _isCompleted = val ?? false),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Schedule Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
