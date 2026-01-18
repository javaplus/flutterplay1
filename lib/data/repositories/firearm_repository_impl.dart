import '../../domain/entities/firearm.dart';
import '../../domain/repositories/firearm_repository.dart';
import '../datasources/firearm_local_datasource.dart';

/// Implementation of FirearmRepository using local data source
class FirearmRepositoryImpl implements FirearmRepository {
  final FirearmLocalDataSource localDataSource;

  FirearmRepositoryImpl(this.localDataSource);

  @override
  Future<List<Firearm>> getAllFirearms() async {
    return await localDataSource.getAllFirearms();
  }

  @override
  Future<Firearm?> getFirearmById(String id) async {
    return await localDataSource.getFirearmById(id);
  }

  @override
  Future<void> addFirearm(Firearm firearm) async {
    await localDataSource.addFirearm(firearm);
  }

  @override
  Future<void> updateFirearm(Firearm firearm) async {
    await localDataSource.updateFirearm(firearm);
  }

  @override
  Future<void> deleteFirearm(String id) async {
    await localDataSource.deleteFirearm(id);
  }

  @override
  Future<List<Firearm>> searchFirearms(String query) async {
    return await localDataSource.searchFirearms(query);
  }
}
