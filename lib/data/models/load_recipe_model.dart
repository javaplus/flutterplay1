import 'package:drift/drift.dart';
import 'dart:convert';

/// Drift table definition for LoadRecipe
@DataClassName('LoadRecipeData')
class LoadRecipes extends Table {
  TextColumn get loadId => text()();
  TextColumn get nickname => text()();
  TextColumn get cartridge => text()();
  RealColumn get bulletWeight => real()();
  TextColumn get bulletType => text()();
  BoolColumn get isFactoryAmmo =>
      boolean().withDefault(const Constant(false))();
  TextColumn get powderType => text().nullable()();
  RealColumn get powderCharge => real().nullable()();
  TextColumn get primerType => text().nullable()();
  TextColumn get brassType => text().nullable()();
  TextColumn get brassPrep => text().nullable()();
  RealColumn get coalLength => real().nullable()();
  RealColumn get seatingDepth => real().nullable()();
  TextColumn get crimp => text().nullable()();
  TextColumn get pressureSigns => text()(); // Stored as JSON array
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {loadId};
}

/// Type converter for pressure signs list
class PressureSignsConverter extends TypeConverter<List<String>, String> {
  const PressureSignsConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      final decoded = json.decode(fromDb);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}
