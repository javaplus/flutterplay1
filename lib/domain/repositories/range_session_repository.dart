import '../entities/range_session.dart';

/// Repository interface for RangeSession operations
abstract class RangeSessionRepository {
  /// Get all range sessions
  Future<List<RangeSession>> getAllRangeSessions();

  /// Get a range session by ID
  Future<RangeSession?> getRangeSessionById(String id);

  /// Get range sessions by firearm ID
  Future<List<RangeSession>> getRangeSessionsByFirearmId(String firearmId);

  /// Get range sessions by load recipe ID
  Future<List<RangeSession>> getRangeSessionsByLoadRecipeId(
    String loadRecipeId,
  );

  /// Add a new range session
  Future<void> addRangeSession(RangeSession session);

  /// Update an existing range session
  Future<void> updateRangeSession(RangeSession session);

  /// Delete a range session by ID
  Future<void> deleteRangeSession(String id);

  /// Search range sessions by location
  Future<List<RangeSession>> searchRangeSessions(String query);
}
