import '../../domain/entities/range_session.dart';
import '../../domain/repositories/range_session_repository.dart';
import '../datasources/range_session_local_datasource.dart';

/// Implementation of RangeSessionRepository using local data source
class RangeSessionRepositoryImpl implements RangeSessionRepository {
  final RangeSessionLocalDataSource localDataSource;

  RangeSessionRepositoryImpl(this.localDataSource);

  @override
  Future<List<RangeSession>> getAllRangeSessions() async {
    return await localDataSource.getAllRangeSessions();
  }

  @override
  Future<RangeSession?> getRangeSessionById(String id) async {
    return await localDataSource.getRangeSessionById(id);
  }

  @override
  Future<List<RangeSession>> getRangeSessionsByFirearmId(
    String firearmId,
  ) async {
    return await localDataSource.getRangeSessionsByFirearmId(firearmId);
  }

  @override
  Future<List<RangeSession>> getRangeSessionsByLoadRecipeId(
    String loadRecipeId,
  ) async {
    return await localDataSource.getRangeSessionsByLoadRecipeId(loadRecipeId);
  }

  @override
  Future<void> addRangeSession(RangeSession session) async {
    await localDataSource.addRangeSession(session);
  }

  @override
  Future<void> updateRangeSession(RangeSession session) async {
    await localDataSource.updateRangeSession(session);
  }

  @override
  Future<void> deleteRangeSession(String id) async {
    await localDataSource.deleteRangeSession(id);
  }
}
