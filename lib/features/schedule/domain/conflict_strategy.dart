enum ConflictStrategy {
  skipConflicts('Skip Conflicts', 'Only insert non-overlapping activities.'),
  overwrite(
    'Clear & Overwrite',
    'Clear existing activities on that date and apply full routine.',
  ),
  abortOnConflict(
    'Cancel on Conflict',
    'Cancel the operation if any activity overlaps.',
  );

  const ConflictStrategy(this.displayName, this.description);

  final String displayName;
  final String description;
}
