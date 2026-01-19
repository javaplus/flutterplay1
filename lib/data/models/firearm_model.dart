import 'package:drift/drift.dart';

/// Drift table definition for Firearm
@DataClassName('FirearmData')
class Firearms extends Table {
  TextColumn get firearmId => text()();
  TextColumn get name => text()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  TextColumn get caliber => text()();
  RealColumn get barrelLength => real()();
  TextColumn get barrelTwistRate => text()();
  IntColumn get roundCount => integer().withDefault(const Constant(0))();
  TextColumn get opticInfo => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {firearmId};
}
