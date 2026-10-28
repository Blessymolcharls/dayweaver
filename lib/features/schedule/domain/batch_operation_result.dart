class BatchOperationResult {
  final bool success;
  final int addedCount;
  final int skippedCount;
  final String? errorMessage;

  const BatchOperationResult({
    required this.success,
    this.addedCount = 0,
    this.skippedCount = 0,
    this.errorMessage,
  });

  factory BatchOperationResult.success({
    int addedCount = 0,
    int skippedCount = 0,
  }) => BatchOperationResult(
    success: true,
    addedCount: addedCount,
    skippedCount: skippedCount,
  );

  factory BatchOperationResult.failure(String message) =>
      BatchOperationResult(success: false, errorMessage: message);
}
