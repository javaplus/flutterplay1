import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'firearm_model.dart';
import 'load_recipe_model.dart';
import 'range_session_model.dart';
import 'shot_velocity_model.dart';
import '../../domain/entities/firearm.dart' as domain;
import '../../domain/entities/load_recipe.dart' as domain_load;
import '../../domain/entities/range_session.dart' as domain_session;
import '../../domain/entities/target.dart' as domain_target;
import '../../domain/entities/shot_velocity.dart' as domain_shot;

part 'app_database.g.dart';

/// Main database class for the application
@DriftDatabase(
  tables: [Firearms, LoadRecipes, RangeSessions, Targets, ShotVelocities],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 8;

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
      if (from < 3) {
        // Migration from version 2 to 3: Add RangeSessions and Targets tables
        await m.createTable(rangeSessions);
        await m.createTable(targets);
      }
      if (from < 4) {
        // Migration from version 3 to 4: Remove location column and make weather nullable
        await m.deleteTable('range_sessions');
        await m.createTable(rangeSessions);
      }
      if (from < 5) {
        // Migration from version 4 to 5: Make brassPrep, seatingDepth, and crimp nullable in LoadRecipes
        await m.deleteTable('load_recipes');
        await m.createTable(loadRecipes);
      }
      if (from < 6) {
        // Migration from version 5 to 6: Move velocity fields to Targets, add ShotVelocities table
        await m.deleteTable('range_sessions');
        await m.deleteTable('targets');
        await m.createTable(rangeSessions);
        await m.createTable(targets);
        await m.createTable(shotVelocities);
      }
      if (from < 7) {
        // Migration from version 6 to 7: Remove groupSizeCm column from Targets
        await m.deleteTable('targets');
        await m.createTable(targets);
      }
      if (from < 8) {
        // Migration from version 7 to 8: Remove roundsFired column from RangeSessions
        await m.deleteTable('range_sessions');
        await m.createTable(rangeSessions);
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

/// Extension to convert RangeSession Drift data class to domain entity
extension RangeSessionExtension on RangeSessionData {
  domain_session.RangeSession toEntity() {
    return domain_session.RangeSession(
      id: sessionId,
      date: date,
      firearmId: firearmId,
      loadRecipeId: loadRecipeId,
      weather: weather,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain entity to RangeSession Drift companion
extension RangeSessionCompanionExtension on domain_session.RangeSession {
  RangeSessionsCompanion toCompanion() {
    return RangeSessionsCompanion(
      sessionId: Value(id),
      date: Value(date),
      firearmId: Value(firearmId),
      loadRecipeId: Value(loadRecipeId),
      weather: Value(weather),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

/// Extension to convert Target Drift data class to domain entity
extension TargetExtension on TargetData {
  domain_target.Target toEntity() {
    return domain_target.Target(
      id: targetId,
      rangeSessionId: rangeSessionId,
      photoPath: photoPath,
      distance: distance,
      numberOfShots: numberOfShots,
      groupSizeInches: groupSizeInches,
      groupSizeMoa: groupSizeMoa,
      avgVelocity: avgVelocity,
      standardDeviation: standardDeviation,
      extremeSpread: extremeSpread,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain entity to Target Drift companion
extension TargetCompanionExtension on domain_target.Target {
  TargetsCompanion toCompanion() {
    return TargetsCompanion(
      targetId: Value(id),
      rangeSessionId: Value(rangeSessionId),
      photoPath: Value(photoPath),
      distance: Value(distance),
      numberOfShots: Value(numberOfShots),
      groupSizeInches: Value(groupSizeInches),
      groupSizeMoa: Value(groupSizeMoa),
      avgVelocity: Value(avgVelocity),
      standardDeviation: Value(standardDeviation),
      extremeSpread: Value(extremeSpread),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

/// Extension to convert ShotVelocity Drift data class to domain entity
extension ShotVelocityExtension on ShotVelocityData {
  domain_shot.ShotVelocity toEntity() {
    return domain_shot.ShotVelocity(
      id: shotId,
      targetId: targetId,
      velocity: velocity,
      timestamp: timestamp,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extension to convert domain entity to ShotVelocity Drift companion
extension ShotVelocityCompanionExtension on domain_shot.ShotVelocity {
  ShotVelocitiesCompanion toCompanion() {
    return ShotVelocitiesCompanion(
      shotId: Value(id),
      targetId: Value(targetId),
      velocity: Value(velocity),
      timestamp: Value(timestamp),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
