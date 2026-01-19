import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'firearm_model.dart';
import 'load_recipe_model.dart';
import '../../domain/entities/firearm.dart' as domain;
import '../../domain/entities/load_recipe.dart' as domain_load;

part 'app_database.g.dart';

/// Main database class for the application
@DriftDatabase(tables: [Firearms, LoadRecipes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Migration from version 1 to 2: Add LoadRecipes table
        await m.createTable(loadRecipes);
      }
    },
  );
}

/// Helper function to create the database
Future<AppDatabase> createDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'firearms.sqlite'));
  return AppDatabase(NativeDatabase(file));
}

/// Extension to convert Drift data class to domain entity
extension FirearmExtension on FirearmData {
  domain.Firearm toEntity() {
    return domain.Firearm(
      id: firearmId,
      name: name,
      make: make,
      model: model,
      caliber: caliber,
      barrelLength: barrelLength,
      barrelTwistRate: barrelTwistRate,
      roundCount: roundCount,
      opticInfo: opticInfo,
      notes: notes,
      photoPath: photoPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain entity to Drift companion
extension FirearmCompanionExtension on domain.Firearm {
  FirearmsCompanion toCompanion() {
    return FirearmsCompanion(
      firearmId: Value(id),
      name: Value(name),
      make: Value(make),
      model: Value(model),
      caliber: Value(caliber),
      barrelLength: Value(barrelLength),
      barrelTwistRate: Value(barrelTwistRate),
      roundCount: Value(roundCount),
      opticInfo: Value(opticInfo),
      notes: Value(notes),
      photoPath: Value(photoPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

/// Extension to convert LoadRecipe Drift data class to domain entity
extension LoadRecipeExtension on LoadRecipeData {
  domain_load.LoadRecipe toEntity() {
    return domain_load.LoadRecipe(
      id: loadId,
      cartridge: cartridge,
      bulletWeight: bulletWeight,
      bulletType: bulletType,
      powderType: powderType,
      powderCharge: powderCharge,
      primerType: primerType,
      brassType: brassType,
      brassPrep: brassPrep,
      coalLength: coalLength,
      seatingDepth: seatingDepth,
      crimp: crimp,
      pressureSigns: const PressureSignsConverter().fromSql(pressureSigns),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain entity to LoadRecipe Drift companion
extension LoadRecipeCompanionExtension on domain_load.LoadRecipe {
  LoadRecipesCompanion toCompanion() {
    return LoadRecipesCompanion(
      loadId: Value(id),
      cartridge: Value(cartridge),
      bulletWeight: Value(bulletWeight),
      bulletType: Value(bulletType),
      powderType: Value(powderType),
      powderCharge: Value(powderCharge),
      primerType: Value(primerType),
      brassType: Value(brassType),
      brassPrep: Value(brassPrep),
      coalLength: Value(coalLength),
      seatingDepth: Value(seatingDepth),
      crimp: Value(crimp),
      pressureSigns: Value(const PressureSignsConverter().toSql(pressureSigns)),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
