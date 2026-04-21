import '../models/export_data.dart';

/// Service for migrating export data between schema versions
///
/// This class handles transformation of old export formats to the current
/// format, enabling backwards compatibility for user backups.
///
/// See EXPORT_COMPATIBILITY_GUIDE.md for migration patterns and examples.
class DataMigrator {
  /// Migrate export data from any supported version to current version
  ///
  /// Applies migrations in sequence: v1 → v2 → v3 → ... → current
  ///
  /// Throws [UnsupportedSchemaVersionException] if schema version is not supported
  static ExportData migrate(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int;

    // Check if version is supported
    if (schemaVersion > currentExportSchemaVersion) {
      throw UnsupportedSchemaVersionException(
        'Export schema v$schemaVersion is newer than supported v$currentExportSchemaVersion. '
        'Please update the app to import this backup.',
      );
    }

    if (schemaVersion < minCompatibleSchemaVersion) {
      throw UnsupportedSchemaVersionException(
        'Export schema v$schemaVersion is too old. '
        'Minimum supported version is v$minCompatibleSchemaVersion.',
      );
    }

    // If already current version, no migration needed
    if (schemaVersion == currentExportSchemaVersion) {
      return ExportData.fromJson(json);
    }

    // Apply migrations in sequence
    var currentJson = json;

    // Example: When v2 is implemented, add:
    // if (schemaVersion < 2) {
    //   currentJson = _migrateV1ToV2(currentJson);
    // }
    //
    // if (schemaVersion < 3) {
    //   currentJson = _migrateV2ToV3(currentJson);
    // }

    // Parse final migrated JSON
    return ExportData.fromJson(currentJson);
  }

  /// Example migration method (for future use when v2 is implemented)
  ///
  /// Uncomment and implement when breaking changes require v2 schema:
  ///
  /// ```dart
  /// /// Migrate v1 structure to v2 structure
  /// ///
  /// /// Changes in v2:
  /// /// - FirearmExport: Renamed 'model' field to 'modelNumber'
  /// /// - Added new optional field 'serialNumber' to FirearmExport
  /// static Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> json) {
  ///   final migrated = Map<String, dynamic>.from(json);
  ///
  ///   // Transform firearms array
  ///   if (migrated.containsKey('firearms')) {
  ///     migrated['firearms'] = (migrated['firearms'] as List).map((f) {
  ///       final firearm = Map<String, dynamic>.from(f);
  ///
  ///       // Rename 'model' to 'modelNumber'
  ///       if (firearm.containsKey('model')) {
  ///         firearm['modelNumber'] = firearm.remove('model');
  ///       }
  ///
  ///       // Add default for new optional field (will be null)
  ///       // serialNumber is already optional, so no action needed
  ///
  ///       return firearm;
  ///     }).toList();
  ///   }
  ///
  ///   // Update schema version
  ///   migrated['schemaVersion'] = 2;
  ///
  ///   return migrated;
  /// }
  /// ```

  /// Validate that migrated data matches expected structure
  ///
  /// This is a lightweight validation to catch obvious migration errors.
  /// Full schema validation should be done in tests.
  static void validateMigrated(ExportData data) {
    if (data.schemaVersion != currentExportSchemaVersion) {
      throw MigrationValidationException(
        'Migration failed: schema version is ${data.schemaVersion}, '
        'expected $currentExportSchemaVersion',
      );
    }

    // Basic referential integrity checks
    final firearmIds = data.firearms.map((f) => f.id).toSet();
    final recipeIds = data.loadRecipes.map((r) => r.id).toSet();
    final sessionIds = data.rangeSessions.map((s) => s.id).toSet();
    final targetIds = data.targets.map((t) => t.id).toSet();

    // Check that foreign keys reference valid entities
    for (final session in data.rangeSessions) {
      if (!firearmIds.contains(session.firearmId)) {
        throw MigrationValidationException(
          'Range session ${session.id} references non-existent firearm ${session.firearmId}',
        );
      }
      if (!recipeIds.contains(session.loadRecipeId)) {
        throw MigrationValidationException(
          'Range session ${session.id} references non-existent load recipe ${session.loadRecipeId}',
        );
      }
    }

    for (final target in data.targets) {
      if (!sessionIds.contains(target.rangeSessionId)) {
        throw MigrationValidationException(
          'Target ${target.id} references non-existent range session ${target.rangeSessionId}',
        );
      }
    }

    for (final shot in data.shotVelocities) {
      if (!targetIds.contains(shot.targetId)) {
        throw MigrationValidationException(
          'Shot velocity ${shot.id} references non-existent target ${shot.targetId}',
        );
      }
    }
  }

  /// Get a human-readable description of what migrations will be applied
  static String getMigrationDescription(int fromVersion, int toVersion) {
    if (fromVersion == toVersion) {
      return 'No migration needed (already v$fromVersion)';
    }

    final migrations = <String>[];

    // Add descriptions for each migration step
    // Example for future v2:
    // if (fromVersion < 2 && toVersion >= 2) {
    //   migrations.add('v1 → v2: Rename FirearmExport.model to modelNumber');
    // }

    if (migrations.isEmpty) {
      return 'Migrate v$fromVersion → v$toVersion (no structural changes)';
    }

    return 'Migrate v$fromVersion → v$toVersion:\n' +
        migrations.map((m) => '  - $m').join('\n');
  }
}

/// Exception thrown when an unsupported schema version is encountered
class UnsupportedSchemaVersionException implements Exception {
  final String message;

  UnsupportedSchemaVersionException(this.message);

  @override
  String toString() => 'UnsupportedSchemaVersionException: $message';
}

/// Exception thrown when migration validation fails
class MigrationValidationException implements Exception {
  final String message;

  MigrationValidationException(this.message);

  @override
  String toString() => 'MigrationValidationException: $message';
}
