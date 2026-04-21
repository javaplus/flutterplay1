import 'dart:convert';

import '../../domain/entities/firearm.dart';
import '../../domain/entities/load_recipe.dart';
import '../../domain/entities/range_session.dart';
import '../../domain/entities/target.dart';
import '../../domain/entities/shot_velocity.dart';

/// Current export schema version
/// Increment this when making breaking changes to the export format
const int currentExportSchemaVersion = 1;

/// Minimum schema version that can be imported (for backwards compatibility)
const int minCompatibleSchemaVersion = 1;

/// Model representing the complete exported data structure
class ExportData {
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final ExportMetadata metadata;
  final List<FirearmExport> firearms;
  final List<LoadRecipeExport> loadRecipes;
  final List<RangeSessionExport> rangeSessions;
  final List<TargetExport> targets;
  final List<ShotVelocityExport> shotVelocities;

  ExportData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.metadata,
    required this.firearms,
    required this.loadRecipes,
    required this.rangeSessions,
    required this.targets,
    required this.shotVelocities,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'metadata': metadata.toJson(),
      'firearms': firearms.map((f) => f.toJson()).toList(),
      'loadRecipes': loadRecipes.map((l) => l.toJson()).toList(),
      'rangeSessions': rangeSessions.map((r) => r.toJson()).toList(),
      'targets': targets.map((t) => t.toJson()).toList(),
      'shotVelocities': shotVelocities.map((s) => s.toJson()).toList(),
    };
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      schemaVersion: json['schemaVersion'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      appVersion: json['appVersion'] as String,
      metadata: ExportMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      firearms: (json['firearms'] as List)
          .map((f) => FirearmExport.fromJson(f as Map<String, dynamic>))
          .toList(),
      loadRecipes: (json['loadRecipes'] as List)
          .map((l) => LoadRecipeExport.fromJson(l as Map<String, dynamic>))
          .toList(),
      rangeSessions: (json['rangeSessions'] as List)
          .map((r) => RangeSessionExport.fromJson(r as Map<String, dynamic>))
          .toList(),
      targets: (json['targets'] as List)
          .map((t) => TargetExport.fromJson(t as Map<String, dynamic>))
          .toList(),
      shotVelocities: (json['shotVelocities'] as List)
          .map((s) => ShotVelocityExport.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory ExportData.fromJsonString(String jsonString) {
    return ExportData.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }
}

/// Metadata about the export
class ExportMetadata {
  final int totalFirearms;
  final int totalLoadRecipes;
  final int totalRangeSessions;
  final int totalTargets;
  final int totalShotVelocities;
  final int totalImages;
  final Map<String, String>
  imageManifest; // Maps entity ID to relative image path in archive

  ExportMetadata({
    required this.totalFirearms,
    required this.totalLoadRecipes,
    required this.totalRangeSessions,
    required this.totalTargets,
    required this.totalShotVelocities,
    required this.totalImages,
    required this.imageManifest,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalFirearms': totalFirearms,
      'totalLoadRecipes': totalLoadRecipes,
      'totalRangeSessions': totalRangeSessions,
      'totalTargets': totalTargets,
      'totalShotVelocities': totalShotVelocities,
      'totalImages': totalImages,
      'imageManifest': imageManifest,
    };
  }

  factory ExportMetadata.fromJson(Map<String, dynamic> json) {
    return ExportMetadata(
      totalFirearms: json['totalFirearms'] as int,
      totalLoadRecipes: json['totalLoadRecipes'] as int,
      totalRangeSessions: json['totalRangeSessions'] as int,
      totalTargets: json['totalTargets'] as int,
      totalShotVelocities: json['totalShotVelocities'] as int,
      totalImages: json['totalImages'] as int,
      imageManifest: Map<String, String>.from(json['imageManifest'] as Map),
    );
  }
}

/// Export model for Firearm entity
class FirearmExport {
  final String id;
  final String name;
  final String make;
  final String model;
  final String caliber;
  final double barrelLength;
  final String barrelTwistRate;
  final int roundCount;
  final String? opticInfo;
  final String? notes;
  final String? imageFileName; // Relative path in archive (not absolute path)
  final DateTime createdAt;
  final DateTime updatedAt;

  FirearmExport({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.caliber,
    required this.barrelLength,
    required this.barrelTwistRate,
    required this.roundCount,
    this.opticInfo,
    this.notes,
    this.imageFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirearmExport.fromEntity(Firearm firearm, {String? imageFileName}) {
    return FirearmExport(
      id: firearm.id,
      name: firearm.name,
      make: firearm.make,
      model: firearm.model,
      caliber: firearm.caliber,
      barrelLength: firearm.barrelLength,
      barrelTwistRate: firearm.barrelTwistRate,
      roundCount: firearm.roundCount,
      opticInfo: firearm.opticInfo,
      notes: firearm.notes,
      imageFileName: imageFileName,
      createdAt: firearm.createdAt,
      updatedAt: firearm.updatedAt,
    );
  }

  Firearm toEntity({String? photoPath}) {
    return Firearm(
      id: id,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'make': make,
      'model': model,
      'caliber': caliber,
      'barrelLength': barrelLength,
      'barrelTwistRate': barrelTwistRate,
      'roundCount': roundCount,
      'opticInfo': opticInfo,
      'notes': notes,
      'imageFileName': imageFileName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FirearmExport.fromJson(Map<String, dynamic> json) {
    return FirearmExport(
      id: json['id'] as String,
      name: json['name'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      caliber: json['caliber'] as String,
      barrelLength: (json['barrelLength'] as num).toDouble(),
      barrelTwistRate: json['barrelTwistRate'] as String,
      roundCount: json['roundCount'] as int,
      opticInfo: json['opticInfo'] as String?,
      notes: json['notes'] as String?,
      imageFileName: json['imageFileName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Export model for LoadRecipe entity
class LoadRecipeExport {
  final String id;
  final String nickname;
  final String cartridge;
  final double bulletWeight;
  final String bulletType;
  final String powderType;
  final double powderCharge;
  final String primerType;
  final String brassType;
  final String? brassPrep;
  final double coalLength;
  final double? seatingDepth;
  final String? crimp;
  final List<String> pressureSigns;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoadRecipeExport({
    required this.id,
    required this.nickname,
    required this.cartridge,
    required this.bulletWeight,
    required this.bulletType,
    required this.powderType,
    required this.powderCharge,
    required this.primerType,
    required this.brassType,
    this.brassPrep,
    required this.coalLength,
    this.seatingDepth,
    this.crimp,
    required this.pressureSigns,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoadRecipeExport.fromEntity(LoadRecipe recipe) {
    return LoadRecipeExport(
      id: recipe.id,
      nickname: recipe.nickname,
      cartridge: recipe.cartridge,
      bulletWeight: recipe.bulletWeight,
      bulletType: recipe.bulletType,
      powderType: recipe.powderType,
      powderCharge: recipe.powderCharge,
      primerType: recipe.primerType,
      brassType: recipe.brassType,
      brassPrep: recipe.brassPrep,
      coalLength: recipe.coalLength,
      seatingDepth: recipe.seatingDepth,
      crimp: recipe.crimp,
      pressureSigns: recipe.pressureSigns,
      notes: recipe.notes,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
    );
  }

  LoadRecipe toEntity() {
    return LoadRecipe(
      id: id,
      nickname: nickname,
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
      pressureSigns: pressureSigns,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'cartridge': cartridge,
      'bulletWeight': bulletWeight,
      'bulletType': bulletType,
      'powderType': powderType,
      'powderCharge': powderCharge,
      'primerType': primerType,
      'brassType': brassType,
      'brassPrep': brassPrep,
      'coalLength': coalLength,
      'seatingDepth': seatingDepth,
      'crimp': crimp,
      'pressureSigns': pressureSigns,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LoadRecipeExport.fromJson(Map<String, dynamic> json) {
    return LoadRecipeExport(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      cartridge: json['cartridge'] as String,
      bulletWeight: (json['bulletWeight'] as num).toDouble(),
      bulletType: json['bulletType'] as String,
      powderType: json['powderType'] as String,
      powderCharge: (json['powderCharge'] as num).toDouble(),
      primerType: json['primerType'] as String,
      brassType: json['brassType'] as String,
      brassPrep: json['brassPrep'] as String?,
      coalLength: (json['coalLength'] as num).toDouble(),
      seatingDepth: (json['seatingDepth'] as num?)?.toDouble(),
      crimp: json['crimp'] as String?,
      pressureSigns: List<String>.from(json['pressureSigns'] as List),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Export model for RangeSession entity
class RangeSessionExport {
  final String id;
  final DateTime date;
  final String firearmId;
  final String loadRecipeId;
  final String? weather;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RangeSessionExport({
    required this.id,
    required this.date,
    required this.firearmId,
    required this.loadRecipeId,
    this.weather,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RangeSessionExport.fromEntity(RangeSession session) {
    return RangeSessionExport(
      id: session.id,
      date: session.date,
      firearmId: session.firearmId,
      loadRecipeId: session.loadRecipeId,
      weather: session.weather,
      notes: session.notes,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }

  RangeSession toEntity() {
    return RangeSession(
      id: id,
      date: date,
      firearmId: firearmId,
      loadRecipeId: loadRecipeId,
      weather: weather,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'firearmId': firearmId,
      'loadRecipeId': loadRecipeId,
      'weather': weather,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RangeSessionExport.fromJson(Map<String, dynamic> json) {
    return RangeSessionExport(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      firearmId: json['firearmId'] as String,
      loadRecipeId: json['loadRecipeId'] as String,
      weather: json['weather'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Export model for Target entity
class TargetExport {
  final String id;
  final String rangeSessionId;
  final String? imageFileName; // Relative path in archive
  final double distance;
  final int numberOfShots;
  final double? groupSizeInches;
  final double? groupSizeMoa;
  final double? avgVelocity;
  final double? standardDeviation;
  final double? extremeSpread;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TargetExport({
    required this.id,
    required this.rangeSessionId,
    this.imageFileName,
    required this.distance,
    required this.numberOfShots,
    this.groupSizeInches,
    this.groupSizeMoa,
    this.avgVelocity,
    this.standardDeviation,
    this.extremeSpread,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TargetExport.fromEntity(Target target, {String? imageFileName}) {
    return TargetExport(
      id: target.id,
      rangeSessionId: target.rangeSessionId,
      imageFileName: imageFileName,
      distance: target.distance,
      numberOfShots: target.numberOfShots,
      groupSizeInches: target.groupSizeInches,
      groupSizeMoa: target.groupSizeMoa,
      avgVelocity: target.avgVelocity,
      standardDeviation: target.standardDeviation,
      extremeSpread: target.extremeSpread,
      notes: target.notes,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt,
    );
  }

  Target toEntity({String? photoPath}) {
    return Target(
      id: id,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rangeSessionId': rangeSessionId,
      'imageFileName': imageFileName,
      'distance': distance,
      'numberOfShots': numberOfShots,
      'groupSizeInches': groupSizeInches,
      'groupSizeMoa': groupSizeMoa,
      'avgVelocity': avgVelocity,
      'standardDeviation': standardDeviation,
      'extremeSpread': extremeSpread,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TargetExport.fromJson(Map<String, dynamic> json) {
    return TargetExport(
      id: json['id'] as String,
      rangeSessionId: json['rangeSessionId'] as String,
      imageFileName: json['imageFileName'] as String?,
      distance: (json['distance'] as num).toDouble(),
      numberOfShots: json['numberOfShots'] as int,
      groupSizeInches: (json['groupSizeInches'] as num?)?.toDouble(),
      groupSizeMoa: (json['groupSizeMoa'] as num?)?.toDouble(),
      avgVelocity: (json['avgVelocity'] as num?)?.toDouble(),
      standardDeviation: (json['standardDeviation'] as num?)?.toDouble(),
      extremeSpread: (json['extremeSpread'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Export model for ShotVelocity entity
class ShotVelocityExport {
  final String id;
  final String targetId;
  final double velocity;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShotVelocityExport({
    required this.id,
    required this.targetId,
    required this.velocity,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShotVelocityExport.fromEntity(ShotVelocity shot) {
    return ShotVelocityExport(
      id: shot.id,
      targetId: shot.targetId,
      velocity: shot.velocity,
      timestamp: shot.timestamp,
      createdAt: shot.createdAt,
      updatedAt: shot.updatedAt,
    );
  }

  ShotVelocity toEntity() {
    return ShotVelocity(
      id: id,
      targetId: targetId,
      velocity: velocity,
      timestamp: timestamp,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'velocity': velocity,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShotVelocityExport.fromJson(Map<String, dynamic> json) {
    return ShotVelocityExport(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      velocity: (json['velocity'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Import mode options
enum ImportMode {
  /// Merge new data with existing data (skip duplicates by ID)
  merge,

  /// Replace all existing data with imported data
  replace,
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final String? errorMessage;
  final int firearmsImported;
  final int firearmsSkipped;
  final int loadRecipesImported;
  final int loadRecipesSkipped;
  final int rangeSessionsImported;
  final int rangeSessionsSkipped;
  final int targetsImported;
  final int targetsSkipped;
  final int shotVelocitiesImported;
  final int shotVelocitiesSkipped;
  final int imagesImported;

  ImportResult({
    required this.success,
    this.errorMessage,
    this.firearmsImported = 0,
    this.firearmsSkipped = 0,
    this.loadRecipesImported = 0,
    this.loadRecipesSkipped = 0,
    this.rangeSessionsImported = 0,
    this.rangeSessionsSkipped = 0,
    this.targetsImported = 0,
    this.targetsSkipped = 0,
    this.shotVelocitiesImported = 0,
    this.shotVelocitiesSkipped = 0,
    this.imagesImported = 0,
  });

  int get totalImported =>
      firearmsImported +
      loadRecipesImported +
      rangeSessionsImported +
      targetsImported +
      shotVelocitiesImported;

  int get totalSkipped =>
      firearmsSkipped +
      loadRecipesSkipped +
      rangeSessionsSkipped +
      targetsSkipped +
      shotVelocitiesSkipped;

  factory ImportResult.error(String message) {
    return ImportResult(success: false, errorMessage: message);
  }
}

/// Progress information during export/import
class ExportImportProgress {
  final String stage;
  final int current;
  final int total;
  final double percentage;

  ExportImportProgress({
    required this.stage,
    required this.current,
    required this.total,
  }) : percentage = total > 0 ? (current / total) * 100 : 0;

  @override
  String toString() =>
      '$stage: $current/$total (${percentage.toStringAsFixed(1)}%)';
}
