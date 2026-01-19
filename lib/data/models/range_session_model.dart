import 'package:drift/drift.dart';

/// Drift table definition for RangeSession
@DataClassName('RangeSessionData')
class RangeSessions extends Table {
  TextColumn get sessionId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get firearmId => text()(); // Foreign key to Firearms
  TextColumn get loadRecipeId => text()(); // Foreign key to LoadRecipes
  IntColumn get roundsFired => integer()();
  TextColumn get weather => text().nullable()();
  RealColumn get avgVelocity => real().nullable()();
  RealColumn get standardDeviation => real().nullable()();
  RealColumn get extremeSpread => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId};
}

/// Drift table definition for Target
@DataClassName('TargetData')
class Targets extends Table {
  TextColumn get targetId => text()();
  TextColumn get rangeSessionId => text()(); // Foreign key to RangeSessions
  TextColumn get photoPath => text().nullable()();
  RealColumn get distance => real()();
  IntColumn get numberOfShots => integer()();
  RealColumn get groupSizeInches => real().nullable()();
  RealColumn get groupSizeCm => real().nullable()();
  RealColumn get groupSizeMoa => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {targetId};
}
