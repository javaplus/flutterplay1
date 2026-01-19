import '../entities/shot_velocity.dart';

/// Repository interface for ShotVelocity operations
abstract class ShotVelocityRepository {
  /// Get all shot velocities for a target
  Future<List<ShotVelocity>> getShotVelocitiesByTargetId(String targetId);

  /// Get a single shot velocity by ID
  Future<ShotVelocity?> getShotVelocityById(String id);

  /// Add a new shot velocity
  Future<void> addShotVelocity(ShotVelocity shotVelocity);

  /// Add multiple shot velocities
  Future<void> addShotVelocities(List<ShotVelocity> shotVelocities);

  /// Update an existing shot velocity
  Future<void> updateShotVelocity(ShotVelocity shotVelocity);

  /// Delete a shot velocity by ID
  Future<void> deleteShotVelocity(String id);

  /// Delete all shot velocities for a target
  Future<void> deleteShotVelocitiesByTargetId(String targetId);
}
