import 'routine_template_block.dart';
import 'time_utils.dart';

class RoutineTemplate {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RoutineTemplateBlock> blocks;

  RoutineTemplate({
    required this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoutineTemplateBlock>? blocks,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       blocks = blocks ?? [];

  int get totalPlannedMinutes =>
      blocks.fold(0, (sum, block) => sum + block.durationMinutes);

  String get totalDurationFormatted =>
      TimeUtils.formatDuration(totalPlannedMinutes);

  int get blockCount => blocks.length;

  RoutineTemplate copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoutineTemplateBlock>? blocks,
  }) {
    return RoutineTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      blocks: blocks ?? this.blocks,
    );
  }
}
