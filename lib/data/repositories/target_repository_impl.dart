import '../../domain/entities/target.dart';
import '../../domain/repositories/target_repository.dart';
import '../datasources/target_local_datasource.dart';

/// Implementation of TargetRepository using local data source
class TargetRepositoryImpl implements TargetRepository {
  final TargetLocalDataSource localDataSource;

  TargetRepositoryImpl(this.localDataSource);

  @override
  Future<List<Target>> getTargetsByRangeSessionId(String rangeSessionId) async {
    return await localDataSource.getTargetsByRangeSessionId(rangeSessionId);
  }

  @override
  Future<Target?> getTargetById(String id) async {
    return await localDataSource.getTargetById(id);
  }

  @override
  Future<void> addTarget(Target target) async {
    await localDataSource.addTarget(target);
  }

  @override
  Future<void> updateTarget(Target target) async {
    await localDataSource.updateTarget(target);
  }

  @override
  Future<void> deleteTarget(String id) async {
    await localDataSource.deleteTarget(id);
  }

  @override
  Future<void> deleteTargetsByRangeSessionId(String rangeSessionId) async {
    await localDataSource.deleteTargetsByRangeSessionId(rangeSessionId);
  }
}
