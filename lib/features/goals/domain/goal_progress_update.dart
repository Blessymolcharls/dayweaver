import 'package:flutter/foundation.dart';

@immutable
class GoalProgressUpdate {
  final String id;
  final String goalId;
  final double changeAmount;
  final double resultingValue;
  final String? note;
  final DateTime createdAt;

  GoalProgressUpdate({
    required this.id,
    required this.goalId,
    required this.changeAmount,
    required this.resultingValue,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get changeFormatted {
    if (changeAmount > 0) {
      return '+${_formatNumber(changeAmount)}';
    } else {
      return _formatNumber(changeAmount);
    }
  }

  static String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalProgressUpdate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          changeAmount == other.changeAmount &&
          resultingValue == other.resultingValue &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      changeAmount.hashCode ^
      resultingValue.hashCode ^
      note.hashCode;
}
