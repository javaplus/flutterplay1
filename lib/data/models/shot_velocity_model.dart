import 'package:drift/drift.dart';

/// Drift table definition for ShotVelocity
@DataClassName('ShotVelocityData')
class ShotVelocities extends Table {
  TextColumn get shotId => text()();
  TextColumn get targetId => text()(); // Foreign key to Targets
  RealColumn get velocity => real()();
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {shotId};
}
