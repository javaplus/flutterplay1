import 'package:isar/isar.dart';
import '../../domain/entities/firearm.dart';

part 'firearm_model.g.dart';

/// Isar database model for Firearm
/// This is the data layer representation that maps to the database
@collection
class FirearmModel {
  Id id = Isar.autoIncrement; // Auto-increment ID for Isar

  @Index()
  late String firearmId; // Our custom UUID

  @Index()
  late String name;

  late String make;
  late String model;

  @Index()
  late String caliber;

  late double barrelLength;
  late String barrelTwistRate;
  late int roundCount;

  String? opticInfo;
  String? notes;
  String? photoPath;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  /// Convert to domain entity
  Firearm toEntity() {
    return Firearm(
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

  /// Create from domain entity
  static FirearmModel fromEntity(Firearm firearm) {
    return FirearmModel()
      ..firearmId = firearm.id
      ..name = firearm.name
      ..make = firearm.make
      ..model = firearm.model
      ..caliber = firearm.caliber
      ..barrelLength = firearm.barrelLength
      ..barrelTwistRate = firearm.barrelTwistRate
      ..roundCount = firearm.roundCount
      ..opticInfo = firearm.opticInfo
      ..notes = firearm.notes
      ..photoPath = firearm.photoPath
      ..createdAt = firearm.createdAt
      ..updatedAt = firearm.updatedAt;
  }
}
