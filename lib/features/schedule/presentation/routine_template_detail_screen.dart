import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'activity_providers.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/routine_template.dart';
import '../domain/routine_template_block.dart';
import '../domain/time_utils.dart';
import 'widgets/apply_routine_sheet.dart';

class RoutineTemplateDetailScreen extends ConsumerStatefulWidget {
  final RoutineTemplate template;

  const RoutineTemplateDetailScreen({super.key, required this.template});

  @override
  ConsumerState<RoutineTemplateDetailScreen> createState() =>
      _RoutineTemplateDetailScreenState();
}

class _RoutineTemplateDetailScreenState
    extends ConsumerState<RoutineTemplateDetailScreen> {
  late RoutineTemplate _template;

  @override
  void initState() {
    super.initState();
    _template = widget.template;
  }

  Future<void> _refresh() async {
    final updated = await ref
        .read(activityRepositoryProvider)
        .getTemplateById(_template.id);
    if (updated != null && mounted) {
      setState(() => _template = updated);
    }
  }

  Future<void> _renameTemplate() async {
    final nameController = TextEditingController(text: _template.name);
    final descController = TextEditingController(
      text: _template.description ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Template Info', style: AppTypography.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty && mounted) {
      final updated = _template.copyWith(
        name: nameController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
      );
      await ref.read(activityRepositoryProvider).saveTemplate(updated);
      await _refresh();
    }
  }

  Future<void> _deleteTemplate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Template', style: AppTypography.headingSmall),
        content: Text(
          'Delete "${_template.name}"? Activities already scheduled from this template will NOT be deleted.',
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

    if (confirmed == true && mounted) {
      await ref.read(activityRepositoryProvider).deleteTemplate(_template.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showBlockForm({RoutineTemplateBlock? blockToEdit}) async {
    final titleController = TextEditingController(
      text: blockToEdit?.title ?? '',
    );
    final notesController = TextEditingController(
      text: blockToEdit?.notes ?? '',
    );
    ActivityCategory category =
        blockToEdit?.category ?? ActivityCategory.college;
    ActivityPriority priority =
        blockToEdit?.priority ?? ActivityPriority.medium;
    int startMinute = blockToEdit?.startMinute ?? 540; // 09:00
    int endMinute = blockToEdit?.endMinute ?? 600; // 10:00
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          blockToEdit != null
                              ? 'Edit Routine Block'
                              : 'Add Routine Block',
                          style: AppTypography.headingMedium,
                        ),
                        if (blockToEdit != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(activityRepositoryProvider)
                                  .deleteTemplateBlock(blockToEdit.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (errorText != null) ...[
                      Text(
                        errorText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Block Title *',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category
                    Text('Category', style: AppTypography.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ActivityCategory.values.map((cat) {
                        final isSel = cat == category;
                        return ChoiceChip(
                          avatar: Icon(
                            cat.icon,
                            size: 14,
                            color: isSel ? Colors.white : cat.color,
                          ),
                          label: Text(cat.displayName),
                          selected: isSel,
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSel ? Colors.white : AppColors.textPrimary,
                          ),
                          onSelected: (val) {
                            if (val) setSheetState(() => category = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Time Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: startMinute ~/ 60,
                                  minute: startMinute % 60,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  startMinute =
                                      picked.hour * 60 + picked.minute;
                                  if (endMinute <= startMinute) {
                                    endMinute = (startMinute + 60).clamp(
                                      0,
                                      TimeUtils.minutesPerDay,
                                    );
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'START',
                                    style: AppTypography.labelSmall,
                                  ),
                                  Text(
                                    TimeUtils.formatMinutes(startMinute),
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
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: endMinute >= TimeUtils.minutesPerDay
                                      ? 23
                                      : endMinute ~/ 60,
                                  minute: endMinute >= TimeUtils.minutesPerDay
                                      ? 59
                                      : endMinute % 60,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  endMinute = picked.hour * 60 + picked.minute;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('END', style: AppTypography.labelSmall),
                                  Text(
                                    TimeUtils.formatMinutes(endMinute),
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
                    const SizedBox(height: 14),

                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          setSheetState(() => errorText = 'Title is required');
                          return;
                        }
                        final rangeErr = TimeUtils.validateTimeRange(
                          startMinute,
                          endMinute,
                        );
                        if (rangeErr != null) {
                          setSheetState(() => errorText = rangeErr);
                          return;
                        }

                        // Check overlap against other blocks in template
                        final overlap = TimeUtils.checkOverlap(
                          startMinute: startMinute,
                          endMinute: endMinute,
                          existingActivities: _template.blocks,
                          excludeActivityId: blockToEdit?.id,
                        );

                        if (overlap.hasOverlap) {
                          setSheetState(
                            () => errorText =
                                'Overlaps with "${overlap.conflictingTitle}".',
                          );
                          return;
                        }

                        final block = RoutineTemplateBlock(
                          id: blockToEdit?.id ?? const Uuid().v4(),
                          templateId: _template.id,
                          title: titleController.text.trim(),
                          category: category,
                          startMinute: startMinute,
                          endMinute: endMinute,
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          priority: priority,
                        );

                        await ref
                            .read(activityRepositoryProvider)
                            .saveTemplateBlock(block);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        blockToEdit != null ? 'Save Changes' : 'Add Block',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = List<RoutineTemplateBlock>.from(_template.blocks)
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_template.name, style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename Template',
            onPressed: _renameTemplate,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            tooltip: 'Delete Template',
            onPressed: _deleteTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.surfaceElevated,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${blocks.length} Activities Planned',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total: ${_template.totalDurationFormatted}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: blocks.isEmpty
                      ? null
                      : () {
                          ApplyRoutineSheet.show(
                            context,
                            template: _template,
                            initialDate: ref.read(selectedDateProvider),
                          );
                        },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Apply to Day'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Blocks List
          Expanded(
            child: blocks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.playlist_add_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Blocks in Template',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add schedule blocks for sleep, lectures, study, coding, meals, and rest.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showBlockForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Block'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: blocks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final b = blocks[index];
                      return InkWell(
                        onTap: () => _showBlockForm(blockToEdit: b),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: b.category.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: b.category.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: b.category.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${b.startFormatted} – ${b.endFormatted} (${b.durationFormatted})',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: b.category.color,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: b.category.color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            b.category.displayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: b.category.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      b.title,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (b.notes != null &&
                                        b.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        b.notes!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBlockForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Block'),
      ),
    );
  }
}
