import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'firearm_model.dart';
import '../../domain/entities/firearm.dart' as domain;

part 'app_database.g.dart';

/// Main database class for the application
@DriftDatabase(tables: [Firearms])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
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
