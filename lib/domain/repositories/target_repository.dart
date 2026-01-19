import '../entities/target.dart';

/// Repository interface for Target operations
abstract class TargetRepository {
  /// Get all targets for a range session
  Future<List<Target>> getTargetsByRangeSessionId(String rangeSessionId);

  /// Get a target by ID
  Future<Target?> getTargetById(String id);

  /// Add a new target
  Future<void> addTarget(Target target);

  /// Update an existing target
  Future<void> updateTarget(Target target);

  /// Delete a target by ID
  Future<void> deleteTarget(String id);

  /// Delete all targets for a range session
  Future<void> deleteTargetsByRangeSessionId(String rangeSessionId);
}
