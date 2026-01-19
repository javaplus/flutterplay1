import 'package:drift/drift.dart';
import '../models/app_database.dart';
import '../../domain/entities/firearm.dart' as domain;

/// Local data source for Firearm using Drift database
class FirearmLocalDataSource {
  final AppDatabase database;

  FirearmLocalDataSource(this.database);

  /// Get all firearms
  Future<List<domain.Firearm>> getAllFirearms() async {
    final query = database.select(database.firearms)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    final results = await query.get();
    return results.map((data) => data.toEntity()).toList();
  }

  /// Get a firearm by ID
  Future<domain.Firearm?> getFirearmById(String firearmId) async {
    final query = database.select(database.firearms)
      ..where((t) => t.firearmId.equals(firearmId));
    final result = await query.getSingleOrNull();
    return result?.toEntity();
  }

  /// Add a new firearm
  Future<void> addFirearm(domain.Firearm firearm) async {
    await database.into(database.firearms).insert(firearm.toCompanion());
  }

  /// Update an existing firearm
  Future<void> updateFirearm(domain.Firearm firearm) async {
    await (database.update(database.firearms)
          ..where((t) => t.firearmId.equals(firearm.id)))
        .write(firearm.toCompanion());
  }

  /// Delete a firearm by ID
  Future<void> deleteFirearm(String firearmId) async {
    await (database.delete(
      database.firearms,
    )..where((t) => t.firearmId.equals(firearmId))).go();
  }

  /// Search firearms by name, make, model, or caliber
  Future<List<domain.Firearm>> searchFirearms(String query) async {
    final lowerQuery = query.toLowerCase();

    final results = await database.select(database.firearms).get();

    final filtered = results.where((data) {
      return data.name.toLowerCase().contains(lowerQuery) ||
          data.make.toLowerCase().contains(lowerQuery) ||
          data.model.toLowerCase().contains(lowerQuery) ||
          data.caliber.toLowerCase().contains(lowerQuery);
    }).toList();

    return filtered.map((data) => data.toEntity()).toList();
  }
}
