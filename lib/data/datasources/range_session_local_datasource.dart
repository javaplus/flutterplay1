import 'package:drift/drift.dart';
import '../models/app_database.dart';
import '../../domain/entities/range_session.dart' as domain;

/// Local data source for RangeSession using Drift database
class RangeSessionLocalDataSource {
  final AppDatabase database;

  RangeSessionLocalDataSource(this.database);

  /// Get all range sessions
  Future<List<domain.RangeSession>> getAllRangeSessions() async {
    final query = database.select(database.rangeSessions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get a range session by ID
  Future<domain.RangeSession?> getRangeSessionById(String sessionId) async {
    final query = database.select(database.rangeSessions)
      ..where((t) => t.sessionId.equals(sessionId));
    final result = await query.getSingleOrNull();
    return result?.toEntity();
  }

  /// Get range sessions by firearm ID
  Future<List<domain.RangeSession>> getRangeSessionsByFirearmId(
    String firearmId,
  ) async {
    final query = database.select(database.rangeSessions)
      ..where((t) => t.firearmId.equals(firearmId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get range sessions by load recipe ID
  Future<List<domain.RangeSession>> getRangeSessionsByLoadRecipeId(
    String loadRecipeId,
  ) async {
    final query = database.select(database.rangeSessions)
      ..where((t) => t.loadRecipeId.equals(loadRecipeId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Add a new range session
  Future<void> addRangeSession(domain.RangeSession session) async {
    await database.into(database.rangeSessions).insert(session.toCompanion());
  }

  /// Update an existing range session
  Future<void> updateRangeSession(domain.RangeSession session) async {
    await (database.update(database.rangeSessions)
          ..where((t) => t.sessionId.equals(session.id)))
        .write(session.toCompanion());
  }

  /// Delete a range session by ID
  Future<void> deleteRangeSession(String sessionId) async {
    await (database.delete(
      database.rangeSessions,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }
}
