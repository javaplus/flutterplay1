import '../../domain/entities/shot_velocity.dart';
import '../../domain/repositories/shot_velocity_repository.dart';
import '../datasources/shot_velocity_local_datasource.dart';

/// Implementation of ShotVelocityRepository using local data source
class ShotVelocityRepositoryImpl implements ShotVelocityRepository {
  final ShotVelocityLocalDataSource localDataSource;

  ShotVelocityRepositoryImpl(this.localDataSource);

  @override
  Future<List<ShotVelocity>> getShotVelocitiesByTargetId(
    String targetId,
  ) async {
    return await localDataSource.getShotVelocitiesByTargetId(targetId);
  }

  @override
  Future<ShotVelocity?> getShotVelocityById(String id) async {
    return await localDataSource.getShotVelocityById(id);
  }

  @override
  Future<void> addShotVelocity(ShotVelocity shotVelocity) async {
    await localDataSource.addShotVelocity(shotVelocity);
  }

  @override
  Future<void> addShotVelocities(List<ShotVelocity> shotVelocities) async {
    await localDataSource.addShotVelocities(shotVelocities);
  }

  @override
  Future<void> updateShotVelocity(ShotVelocity shotVelocity) async {
    await localDataSource.updateShotVelocity(shotVelocity);
  }

  @override
  Future<void> deleteShotVelocity(String id) async {
    await localDataSource.deleteShotVelocity(id);
  }

  @override
  Future<void> deleteShotVelocitiesByTargetId(String targetId) async {
    await localDataSource.deleteShotVelocitiesByTargetId(targetId);
  }
}
