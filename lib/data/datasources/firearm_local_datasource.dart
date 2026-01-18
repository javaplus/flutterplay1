import 'package:isar/isar.dart';
import '../models/firearm_model.dart';
import '../../domain/entities/firearm.dart';

/// Local data source for Firearm using Isar database
class FirearmLocalDataSource {
  final Isar isar;

  FirearmLocalDataSource(this.isar);

  /// Get all firearms
  Future<List<Firearm>> getAllFirearms() async {
    final models = await isar.firearmModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return models.map((model) => model.toEntity()).toList();
  }

  /// Get a firearm by ID
  Future<Firearm?> getFirearmById(String firearmId) async {
    final model = await isar.firearmModels
        .filter()
        .firearmIdEqualTo(firearmId)
        .findFirst();
    return model?.toEntity();
  }

  /// Add a new firearm
  Future<void> addFirearm(Firearm firearm) async {
    final model = FirearmModel.fromEntity(firearm);
    await isar.writeTxn(() async {
      await isar.firearmModels.put(model);
    });
  }

  /// Update an existing firearm
  Future<void> updateFirearm(Firearm firearm) async {
    final existingModel = await isar.firearmModels
        .filter()
        .firearmIdEqualTo(firearm.id)
        .findFirst();

    if (existingModel != null) {
      final updatedModel = FirearmModel.fromEntity(firearm)
        ..id = existingModel.id; // Keep the same Isar auto-increment ID

      await isar.writeTxn(() async {
        await isar.firearmModels.put(updatedModel);
      });
    }
  }

  /// Delete a firearm by ID
  Future<void> deleteFirearm(String firearmId) async {
    await isar.writeTxn(() async {
      await isar.firearmModels
          .filter()
          .firearmIdEqualTo(firearmId)
          .deleteFirst();
    });
  }

  /// Search firearms by name, make, model, or caliber
  Future<List<Firearm>> searchFirearms(String query) async {
    final lowerQuery = query.toLowerCase();

    final models = await isar.firearmModels.where().findAll();

    final filtered = models.where((model) {
      return model.name.toLowerCase().contains(lowerQuery) ||
          model.make.toLowerCase().contains(lowerQuery) ||
          model.model.toLowerCase().contains(lowerQuery) ||
          model.caliber.toLowerCase().contains(lowerQuery);
    }).toList();

    return filtered.map((model) => model.toEntity()).toList();
  }
}
