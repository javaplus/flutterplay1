import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/firearm_model.dart';
import '../../data/datasources/firearm_local_datasource.dart';
import '../../data/repositories/firearm_repository_impl.dart';
import '../../domain/repositories/firearm_repository.dart';
import '../../domain/entities/firearm.dart';

/// Provider for Isar database instance
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main.dart');
});

/// Provider for Firearm local data source
final firearmLocalDataSourceProvider = Provider<FirearmLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return FirearmLocalDataSource(isar);
});

/// Provider for Firearm repository
final firearmRepositoryProvider = Provider<FirearmRepository>((ref) {
  final localDataSource = ref.watch(firearmLocalDataSourceProvider);
  return FirearmRepositoryImpl(localDataSource);
});

/// Provider for the list of all firearms
final firearmsListProvider = FutureProvider<List<Firearm>>((ref) async {
  final repository = ref.watch(firearmRepositoryProvider);
  return await repository.getAllFirearms();
});

/// Provider for a single firearm by ID
final firearmByIdProvider = FutureProvider.family<Firearm?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(firearmRepositoryProvider);
  return await repository.getFirearmById(id);
});

/// Provider for search results
final firearmSearchProvider = FutureProvider.family<List<Firearm>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(firearmRepositoryProvider);
  if (query.isEmpty) {
    return await repository.getAllFirearms();
  }
  return await repository.searchFirearms(query);
});

/// Notifier for managing firearm CRUD operations
class FirearmNotifier extends StateNotifier<AsyncValue<void>> {
  final FirearmRepository repository;

  FirearmNotifier(this.repository) : super(const AsyncValue.data(null));

  /// Add a new firearm
  Future<void> addFirearm(Firearm firearm) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addFirearm(firearm);
    });
  }

  /// Update an existing firearm
  Future<void> updateFirearm(Firearm firearm) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateFirearm(firearm);
    });
  }

  /// Delete a firearm
  Future<void> deleteFirearm(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteFirearm(id);
    });
  }
}

/// Provider for firearm notifier
final firearmNotifierProvider =
    StateNotifierProvider<FirearmNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(firearmRepositoryProvider);
      return FirearmNotifier(repository);
    });

/// Helper function to initialize Isar database
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open([FirearmModelSchema], directory: dir.path);
}
