import 'package:drift/drift.dart';
import '../models/app_database.dart';
import '../../domain/entities/shot_velocity.dart' as domain;

/// Local data source for ShotVelocity using Drift database
class ShotVelocityLocalDataSource {
  final AppDatabase database;

  ShotVelocityLocalDataSource(this.database);

  /// Get all shot velocities for a target
  Future<List<domain.ShotVelocity>> getShotVelocitiesByTargetId(
    String targetId,
  ) async {
    final query = database.select(database.shotVelocities)
      ..where((t) => t.targetId.equals(targetId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get a single shot velocity by ID
  Future<domain.ShotVelocity?> getShotVelocityById(String shotId) async {
    final query = database.select(database.shotVelocities)
      ..where((t) => t.shotId.equals(shotId));
    final result = await query.getSingleOrNull();
    return result?.toEntity();
  }

  /// Add a new shot velocity
  Future<void> addShotVelocity(domain.ShotVelocity shotVelocity) async {
    await database
        .into(database.shotVelocities)
        .insert(shotVelocity.toCompanion());
  }

  /// Add multiple shot velocities
  Future<void> addShotVelocities(
    List<domain.ShotVelocity> shotVelocities,
  ) async {
    await database.batch((batch) {
      batch.insertAll(
        database.shotVelocities,
        shotVelocities.map((sv) => sv.toCompanion()).toList(),
      );
    });
  }

  /// Update an existing shot velocity
  Future<void> updateShotVelocity(domain.ShotVelocity shotVelocity) async {
    await (database.update(database.shotVelocities)
          ..where((t) => t.shotId.equals(shotVelocity.id)))
        .write(shotVelocity.toCompanion());
  }

  /// Delete a shot velocity by ID
  Future<void> deleteShotVelocity(String shotId) async {
    await (database.delete(
      database.shotVelocities,
    )..where((t) => t.shotId.equals(shotId))).go();
  }

  /// Delete all shot velocities for a target
  Future<void> deleteShotVelocitiesByTargetId(String targetId) async {
    await (database.delete(
      database.shotVelocities,
    )..where((t) => t.targetId.equals(targetId))).go();
  }
}
