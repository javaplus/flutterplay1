import 'package:drift/drift.dart';
import '../models/app_database.dart';
import '../../domain/entities/target.dart' as domain;

/// Local data source for Target using Drift database
class TargetLocalDataSource {
  final AppDatabase database;

  TargetLocalDataSource(this.database);

  /// Get all targets for a range session
  Future<List<domain.Target>> getTargetsByRangeSessionId(
    String rangeSessionId,
  ) async {
    final query = database.select(database.targets)
      ..where((t) => t.rangeSessionId.equals(rangeSessionId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get a target by ID
  Future<domain.Target?> getTargetById(String targetId) async {
    final query = database.select(database.targets)
      ..where((t) => t.targetId.equals(targetId));
    final result = await query.getSingleOrNull();
    return result?.toEntity();
  }

  /// Add a new target
  Future<void> addTarget(domain.Target target) async {
    await database.into(database.targets).insert(target.toCompanion());
  }

  /// Update an existing target
  Future<void> updateTarget(domain.Target target) async {
    await (database.update(
      database.targets,
    )..where((t) => t.targetId.equals(target.id))).write(target.toCompanion());
  }

  /// Delete a target by ID
  Future<void> deleteTarget(String targetId) async {
    await (database.delete(
      database.targets,
    )..where((t) => t.targetId.equals(targetId))).go();
  }

  /// Delete all targets for a range session
  Future<void> deleteTargetsByRangeSessionId(String rangeSessionId) async {
    await (database.delete(
      database.targets,
    )..where((t) => t.rangeSessionId.equals(rangeSessionId))).go();
  }
}
