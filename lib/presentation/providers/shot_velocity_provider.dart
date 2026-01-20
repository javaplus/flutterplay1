import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/shot_velocity_local_datasource.dart';
import '../../data/repositories/shot_velocity_repository_impl.dart';
import '../../domain/repositories/shot_velocity_repository.dart';
import '../../domain/entities/shot_velocity.dart';
import 'firearm_provider.dart'; // For databaseProvider

/// Provider for ShotVelocity local data source
final shotVelocityLocalDataSourceProvider =
    Provider<ShotVelocityLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return ShotVelocityLocalDataSource(database);
    });

/// Provider for ShotVelocity repository
final shotVelocityRepositoryProvider = Provider<ShotVelocityRepository>((ref) {
  final localDataSource = ref.watch(shotVelocityLocalDataSourceProvider);
  return ShotVelocityRepositoryImpl(localDataSource);
});

/// Provider for shot velocities by target ID
final shotVelocitiesByTargetIdProvider =
    FutureProvider.family<List<ShotVelocity>, String>((ref, targetId) async {
      final repository = ref.watch(shotVelocityRepositoryProvider);
      return await repository.getShotVelocitiesByTargetId(targetId);
    });

/// Provider for a single shot velocity by ID
final shotVelocityByIdProvider = FutureProvider.family<ShotVelocity?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(shotVelocityRepositoryProvider);
  return await repository.getShotVelocityById(id);
});

/// Notifier for managing shot velocity CRUD operations
class ShotVelocityNotifier extends StateNotifier<AsyncValue<void>> {
  final ShotVelocityRepository repository;

  ShotVelocityNotifier(this.repository) : super(const AsyncValue.data(null));

  /// Add a new shot velocity
  Future<void> addShotVelocity(ShotVelocity shotVelocity) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addShotVelocity(shotVelocity);
    });
  }

  /// Add multiple shot velocities
  Future<void> addShotVelocities(List<ShotVelocity> shotVelocities) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addShotVelocities(shotVelocities);
    });
  }

  /// Update an existing shot velocity
  Future<void> updateShotVelocity(ShotVelocity shotVelocity) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateShotVelocity(shotVelocity);
    });
  }

  /// Delete a shot velocity
  Future<void> deleteShotVelocity(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteShotVelocity(id);
    });
  }

  /// Delete all shot velocities for a target
  Future<void> deleteShotVelocitiesByTargetId(String targetId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteShotVelocitiesByTargetId(targetId);
    });
  }
}

/// Provider for shot velocity notifier
final shotVelocityNotifierProvider =
    StateNotifierProvider<ShotVelocityNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(shotVelocityRepositoryProvider);
      return ShotVelocityNotifier(repository);
    });
