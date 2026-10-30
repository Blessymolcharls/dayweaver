enum GoalStatus {
  active('Active'),
  paused('Paused'),
  completed('Completed'),
  archived('Archived');

  const GoalStatus(this.displayName);

  final String displayName;

  bool get isActive => this == GoalStatus.active;
  bool get isPaused => this == GoalStatus.paused;
  bool get isCompleted => this == GoalStatus.completed;
  bool get isArchived => this == GoalStatus.archived;

  bool get canPause => this == GoalStatus.active;
  bool get canResume => this == GoalStatus.paused;
  bool get canComplete =>
      this == GoalStatus.active || this == GoalStatus.paused;
  bool get canArchive => this != GoalStatus.archived;

  static GoalStatus fromString(String val) {
    return GoalStatus.values.firstWhere(
      (GoalStatus e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GoalStatus.active,
    );
  }
}
