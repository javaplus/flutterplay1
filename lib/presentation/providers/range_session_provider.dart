import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/range_session_local_datasource.dart';
import '../../data/datasources/target_local_datasource.dart';
import '../../data/datasources/shot_velocity_local_datasource.dart';
import '../../data/repositories/range_session_repository_impl.dart';
import '../../data/repositories/target_repository_impl.dart';
import '../../data/repositories/shot_velocity_repository_impl.dart';
import '../../domain/repositories/range_session_repository.dart';
import '../../domain/repositories/target_repository.dart';
import '../../domain/repositories/shot_velocity_repository.dart';
import '../../domain/entities/range_session.dart';
import '../../domain/entities/target.dart';
import 'firearm_provider.dart'; // For databaseProvider

/// Provider for RangeSession local data source
final rangeSessionLocalDataSourceProvider =
    Provider<RangeSessionLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return RangeSessionLocalDataSource(database);
    });

/// Provider for Target local data source
final targetLocalDataSourceProvider = Provider<TargetLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return TargetLocalDataSource(database);
});

/// Provider for ShotVelocity local data source
final shotVelocityLocalDataSourceProvider =
    Provider<ShotVelocityLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return ShotVelocityLocalDataSource(database);
    });

/// Provider for RangeSession repository
final rangeSessionRepositoryProvider = Provider<RangeSessionRepository>((ref) {
  final localDataSource = ref.watch(rangeSessionLocalDataSourceProvider);
  return RangeSessionRepositoryImpl(localDataSource);
});

/// Provider for Target repository
final targetRepositoryProvider = Provider<TargetRepository>((ref) {
  final localDataSource = ref.watch(targetLocalDataSourceProvider);
  return TargetRepositoryImpl(localDataSource);
});

/// Provider for ShotVelocity repository
final shotVelocityRepositoryProvider = Provider<ShotVelocityRepository>((ref) {
  final localDataSource = ref.watch(shotVelocityLocalDataSourceProvider);
  return ShotVelocityRepositoryImpl(localDataSource);
});

/// Provider for the list of all range sessions
final rangeSessionsListProvider = FutureProvider<List<RangeSession>>((
  ref,
) async {
  final repository = ref.watch(rangeSessionRepositoryProvider);
  return await repository.getAllRangeSessions();
});

/// Provider for a single range session by ID
final rangeSessionByIdProvider = FutureProvider.family<RangeSession?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(rangeSessionRepositoryProvider);
  return await repository.getRangeSessionById(id);
});

/// Provider for range sessions by firearm ID
final rangeSessionsByFirearmIdProvider =
    FutureProvider.family<List<RangeSession>, String>((ref, firearmId) async {
      final repository = ref.watch(rangeSessionRepositoryProvider);
      return await repository.getRangeSessionsByFirearmId(firearmId);
    });

/// Provider for range sessions by load recipe ID
final rangeSessionsByLoadRecipeIdProvider =
    FutureProvider.family<List<RangeSession>, String>((
      ref,
      loadRecipeId,
    ) async {
      final repository = ref.watch(rangeSessionRepositoryProvider);
      return await repository.getRangeSessionsByLoadRecipeId(loadRecipeId);
    });

/// Provider for targets by range session ID
final targetsByRangeSessionIdProvider =
    FutureProvider.family<List<Target>, String>((ref, rangeSessionId) async {
      final repository = ref.watch(targetRepositoryProvider);
      return await repository.getTargetsByRangeSessionId(rangeSessionId);
    });

/// Provider for a single target by ID
final targetByIdProvider = FutureProvider.family<Target?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(targetRepositoryProvider);
  return await repository.getTargetById(id);
});

/// Notifier for managing range session CRUD operations
class RangeSessionNotifier extends StateNotifier<AsyncValue<void>> {
  final RangeSessionRepository repository;
  final TargetRepository targetRepository;

  RangeSessionNotifier(this.repository, this.targetRepository)
    : super(const AsyncValue.data(null));

  /// Add a new range session
  Future<void> addRangeSession(RangeSession session) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addRangeSession(session);
    });
  }

  /// Update an existing range session
  Future<void> updateRangeSession(RangeSession session) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateRangeSession(session);
    });
  }

  /// Delete a range session (and all its targets)
  Future<void> deleteRangeSession(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // First delete all associated targets
      await targetRepository.deleteTargetsByRangeSessionId(id);
      // Then delete the session
      await repository.deleteRangeSession(id);
    });
  }
}

/// Notifier for managing target CRUD operations
class TargetNotifier extends StateNotifier<AsyncValue<void>> {
  final TargetRepository repository;
  final ShotVelocityRepository shotVelocityRepository;

  TargetNotifier(this.repository, this.shotVelocityRepository)
    : super(const AsyncValue.data(null));

  /// Add a new target
  Future<void> addTarget(Target target) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addTarget(target);
    });
  }

  /// Update an existing target
  Future<void> updateTarget(Target target) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateTarget(target);
    });
  }

  /// Delete a target
  Future<void> deleteTarget(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // First delete all associated shot velocities
      await shotVelocityRepository.deleteShotVelocitiesByTargetId(id);
      // Then delete the target
      await repository.deleteTarget(id);
    });
  }
}

/// Provider for range session notifier
final rangeSessionNotifierProvider =
    StateNotifierProvider<RangeSessionNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(rangeSessionRepositoryProvider);
      final targetRepository = ref.watch(targetRepositoryProvider);
      return RangeSessionNotifier(repository, targetRepository);
    });

/// Provider for target notifier
final targetNotifierProvider =
    StateNotifierProvider<TargetNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(targetRepositoryProvider);
      final shotVelocityRepository = ref.watch(shotVelocityRepositoryProvider);
      return TargetNotifier(repository, shotVelocityRepository);
    });
