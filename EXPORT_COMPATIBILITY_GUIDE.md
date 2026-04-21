# Export/Import Compatibility Guide

## Overview

This guide defines the rules and best practices for maintaining backwards compatibility in the Reloading Companion export/import system. User data backups are critical - losing the ability to import an old backup is a **critical bug** that must be avoided.

## Current Schema Version

- **Version**: 1
- **Schema Definition**: [`schemas/export_v1.json`](schemas/export_v1.json)
- **Minimum Compatible Version**: 1 (can import all v1 backups)

## Table of Contents

1. [Understanding Breaking vs Non-Breaking Changes](#understanding-breaking-vs-non-breaking-changes)
2. [Schema Versioning Strategy](#schema-versioning-strategy)
3. [Making Non-Breaking Changes](#making-non-breaking-changes)
4. [Making Breaking Changes](#making-breaking-changes)
5. [Migration Framework](#migration-framework)
6. [Testing Backwards Compatibility](#testing-backwards-compatibility)
7. [Examples & Scenarios](#examples--scenarios)

---

## Understanding Breaking vs Non-Breaking Changes

### ✅ Non-Breaking Changes (Safe)

These changes **do not** require incrementing `schemaVersion`:

1. **Adding new optional fields** to existing models
   ```dart
   // ✅ SAFE
   class FirearmExport {
     final String? serialNumber;  // New optional field
   }
   ```

2. **Adding new entity types** to the export (new arrays)
   ```dart
   // ✅ SAFE
   class ExportData {
     final List<NewEntityExport> newEntities;  // New entity type
   }
   ```

3. **Adding new values to metadata** that don't affect entity structure
   ```dart
   // ✅ SAFE
   class ExportMetadata {
     final int totalNewEntities;  // New count
   }
   ```

4. **Expanding nullable fields to accept more values** (still optional)

5. **Adding validation that's more permissive** (accepts more data)

### ❌ Breaking Changes (Require Version Bump)

These changes **require** incrementing `currentExportSchemaVersion`:

1. **Removing fields** from any export model
   ```dart
   // ❌ BREAKING - requires schema v2
   class FirearmExport {
     // final String model;  // Field removed
   }
   ```

2. **Renaming fields**
   ```dart
   // ❌ BREAKING - requires schema v2
   class FirearmExport {
     final String modelNumber;  // Was 'model'
   }
   ```

3. **Changing field types**
   ```dart
   // ❌ BREAKING - requires schema v2
   class FirearmExport {
     final int barrelLength;  // Was 'double'
   }
   ```

4. **Making optional fields required**
   ```dart
   // ❌ BREAKING - requires schema v2
   class FirearmExport {
     final String notes;  // Was 'String?'
   }
   ```

5. **Changing field semantics** (same name/type, different meaning)
   ```dart
   // ❌ BREAKING - requires schema v2
   final double distance;  // Was yards, now meters
   ```

6. **Removing entity types** or making them optional when they were required

7. **Restructuring data** (nested → flat, flat → nested)
   ```dart
   // ❌ BREAKING - requires schema v2
   class LoadRecipeExport {
     final BulletInfo bullet;  // Was flat: bulletWeight, bulletType
   }
   ```

### When in Doubt

**If you're unsure whether a change is breaking, treat it as breaking.** The cost of a false positive (unnecessary version bump) is much lower than a false negative (broken user backups).

**Test question**: "Can an export file created before my change be imported after my change without data loss or error?"
- **Yes** → Non-breaking
- **No or Maybe** → Breaking

---

## Schema Versioning Strategy

### Version Number Format

- Simple integer version: `1`, `2`, `3`, etc.
- Stored in `currentExportSchemaVersion` constant in [`lib/data/models/export_data.dart`](lib/data/models/export_data.dart)
- Exported files include `schemaVersion` field in the root JSON

### Compatibility Window

- `currentExportSchemaVersion`: The version this app exports
- `minCompatibleSchemaVersion`: Oldest version this app can import

**Example scenarios:**

```dart
// App can export v2 and import v1 or v2
const int currentExportSchemaVersion = 2;
const int minCompatibleSchemaVersion = 1;

// App can export v3 and import v2 or v3 (v1 no longer supported)
const int currentExportSchemaVersion = 3;
const int minCompatibleSchemaVersion = 2;
```

### When to Increment Versions

1. **Increment `currentExportSchemaVersion`**: When making any breaking change
2. **Increment `minCompatibleSchemaVersion`**: Only when you **cannot** support older versions (rare!)

⚠️ **Warning**: Incrementing `minCompatibleSchemaVersion` means older backups become unimportable. Avoid unless absolutely necessary.

---

## Making Non-Breaking Changes

### Step-by-Step Process

1. **Add the new optional field** to the export model:
   ```dart
   class FirearmExport {
     // ... existing fields ...
     final String? serialNumber;  // New field
     
     FirearmExport({
       // ... existing params ...
       this.serialNumber,
     });
   }
   ```

2. **Update `toJson()` method**:
   ```dart
   Map<String, dynamic> toJson() {
     return {
       // ... existing fields ...
       'serialNumber': serialNumber,
     };
   }
   ```

3. **Update `fromJson()` to handle missing field**:
   ```dart
   factory FirearmExport.fromJson(Map<String, dynamic> json) {
     return FirearmExport(
       // ... existing fields ...
       serialNumber: json['serialNumber'] as String?,  // Null if missing
     );
   }
   ```

4. **Update JSON Schema** (`schemas/export_v1.json`):
   ```json
   {
     "properties": {
       "serialNumber": {
         "type": ["string", "null"],
         "description": "Optional serial number"
       }
     }
   }
   ```

5. **Update entity conversion methods** (`fromEntity`, `toEntity`):
   ```dart
   factory FirearmExport.fromEntity(Firearm firearm, {String? imageFileName}) {
     return FirearmExport(
       // ... existing fields ...
       serialNumber: firearm.serialNumber,
     );
   }
   
   Firearm toEntity({String? photoPath}) {
     return Firearm(
       // ... existing fields ...
       serialNumber: serialNumber,
     );
   }
   ```

6. **Add tests**:
   - Unit test for new field serialization
   - Test that old exports (without field) still import correctly

7. **Update documentation** (this file) with the change

### Testing Checklist for Non-Breaking Changes

- [ ] Old exports (without new field) import successfully
- [ ] New exports (with new field) import successfully
- [ ] New field is `null` when importing old exports
- [ ] Schema validation passes for both old and new formats
- [ ] All existing tests still pass

---

## Making Breaking Changes

Breaking changes require careful planning and implementation. Follow this comprehensive process:

### Step-by-Step Process

1. **Plan the migration strategy FIRST**
   - How will old data be transformed?
   - What information will be lost (if any)?
   - Can you provide sensible defaults?

2. **Create new schema version**:
   ```bash
   # Copy current schema as reference
   cp schemas/export_v1.json schemas/export_v2.json
   # Update v2 with new structure
   ```

3. **Update schema version constants**:
   ```dart
   // In lib/data/models/export_data.dart
   const int currentExportSchemaVersion = 2;  // Was 1
   const int minCompatibleSchemaVersion = 1;  // Still support v1
   ```

4. **Modify export models** with breaking changes:
   ```dart
   class FirearmExport {
     // Example: Renaming field
     final String modelNumber;  // Was 'model'
   }
   ```

5. **Implement migration logic** in [`lib/data/services/data_migrator.dart`](lib/data/services/data_migrator.dart):
   ```dart
   class DataMigrator {
     /// Migrate export data from old version to current version
     static ExportData migrate(Map<String, dynamic> json) {
       final schemaVersion = json['schemaVersion'] as int;
       
       if (schemaVersion == 1) {
         return _migrateV1ToV2(json);
       }
       
       // No migration needed
       return ExportData.fromJson(json);
     }
     
     static ExportData _migrateV1ToV2(Map<String, dynamic> json) {
       // Transform v1 structure to v2 structure
       final firearms = (json['firearms'] as List).map((f) {
         final firearm = Map<String, dynamic>.from(f);
         // Rename 'model' to 'modelNumber'
         firearm['modelNumber'] = firearm.remove('model');
         return firearm;
       }).toList();
       
       json['firearms'] = firearms;
       json['schemaVersion'] = 2;
       
       return ExportData.fromJson(json);
     }
   }
   ```

6. **Update import service** to use migrator:
   ```dart
   // In data_import_service.dart validateImportFile() and importData()
   final exportData = DataMigrator.migrate(json.decode(jsonString));
   ```

7. **Create test fixtures**:
   ```bash
   # Save sample v1 export
   test/fixtures/export_v1_sample.json
   test/fixtures/export_v1_with_images.zip
   ```

8. **Write migration tests**:
   ```dart
   test('migrates v1 export to v2', () {
     final v1Json = loadFixture('export_v1_sample.json');
     final migrated = DataMigrator.migrate(v1Json);
     
     expect(migrated.schemaVersion, 2);
     expect(migrated.firearms.first.modelNumber, isNotNull);
   });
   ```

9. **Update all documentation**:
   - This compatibility guide
   - JSON Schema files
   - Code comments
   - User-facing changelog

10. **Comprehensive testing** (see Testing section below)

### Breaking Change Checklist

- [ ] New schema version created (`schemas/export_v{N}.json`)
- [ ] `currentExportSchemaVersion` incremented
- [ ] Migration logic implemented in `DataMigrator`
- [ ] Migration tests added with v{N-1} fixtures
- [ ] All existing tests updated for new structure
- [ ] Backwards compatibility tests pass
- [ ] Documentation updated
- [ ] Manual test: Import real v{N-1} backup
- [ ] Consider: Do we need to increment `minCompatibleSchemaVersion`?

---

## Migration Framework

The `DataMigrator` class ([`lib/data/services/data_migrator.dart`](lib/data/services/data_migrator.dart)) handles transformation of old export formats to the current format.

### Architecture

```
Old Export (v1) → DataMigrator.migrate() → Current Format (v2)
                       ↓
              _migrateV1ToV2()
              _migrateV2ToV3()  (if needed later)
              etc.
```

### Migration Pattern

```dart
class DataMigrator {
  /// Main entry point - detects version and applies migrations
  static ExportData migrate(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int;
    
    // Apply migrations in sequence if needed
    var currentJson = json;
    
    if (schemaVersion < 2) {
      currentJson = _migrateV1ToV2Json(currentJson);
    }
    
    if (schemaVersion < 3) {
      currentJson = _migrateV2ToV3Json(currentJson);
    }
    
    // Parse final migrated JSON
    return ExportData.fromJson(currentJson);
  }
  
  /// Migrate v1 structure to v2 structure
  /// Returns modified JSON (does not parse to ExportData)
  static Map<String, dynamic> _migrateV1ToV2Json(Map<String, dynamic> json) {
    // Transform the raw JSON structure
    // Return modified JSON with schemaVersion updated
  }
}
```

### Migration Guidelines

1. **Always work with JSON first**: Migrate raw JSON → JSON, then parse to `ExportData`
2. **Chain migrations**: v1 → v2 → v3 (don't skip versions)
3. **Update schema version**: Set `schemaVersion` field after each migration
4. **Preserve data**: Never lose user data if avoidable
5. **Provide defaults**: Use sensible defaults for new required fields
6. **Document transformations**: Comment complex migrations clearly

### Example Migration

```dart
/// Migrate v1 to v2: Renamed 'model' to 'modelNumber' in FirearmExport
static Map<String, dynamic> _migrateV1ToV2Json(Map<String, dynamic> json) {
  final migrated = Map<String, dynamic>.from(json);
  
  // Transform firearms array
  if (migrated.containsKey('firearms')) {
    final firearms = (migrated['firearms'] as List).map((f) {
      final firearm = Map<String, dynamic>.from(f);
      
      // Rename field
      if (firearm.containsKey('model')) {
        firearm['modelNumber'] = firearm.remove('model');
      }
      
      return firearm;
    }).toList();
    
    migrated['firearms'] = firearms;
  }
  
  // Update schema version
  migrated['schemaVersion'] = 2;
  
  return migrated;
}
```

---

## Testing Backwards Compatibility

### Test Structure

```
test/
├── data/
│   ├── models/
│   │   └── export_data_test.dart          # Schema validation tests
│   └── services/
│       ├── data_export_service_test.dart  # Export tests
│       ├── data_import_service_test.dart  # Import & migration tests
│       └── data_migrator_test.dart        # Migration unit tests
└── fixtures/
    ├── export_v1_sample.json              # Sample v1 export (no images)
    ├── export_v1_full.zip                 # Full v1 export with images
    ├── export_v2_sample.json              # Sample v2 export (future)
    └── README.md                          # Fixture documentation
```

### Key Test Scenarios

1. **Current Version Round-Trip**
   ```dart
   test('export and import current version', () async {
     // Export data → Import data → Verify identical
   });
   ```

2. **Old Version Import**
   ```dart
   test('import v1 export into v2 app', () async {
     final v1Export = loadFixture('export_v1_sample.json');
     final result = await importService.importData(v1Export, ImportMode.replace);
     expect(result.success, true);
   });
   ```

3. **Migration Correctness**
   ```dart
   test('v1 to v2 migration preserves data', () {
     final v1Json = loadFixture('export_v1_sample.json');
     final migrated = DataMigrator.migrate(v1Json);
     
     // Verify data integrity
     expect(migrated.firearms.length, 2);
     expect(migrated.firearms.first.modelNumber, 'Model 70');
   });
   ```

4. **Schema Validation**
   ```dart
   test('exported data validates against schema', () {
     final exported = exportService.exportData();
     final schema = loadSchema('schemas/export_v2.json');
     
     expect(validateJson(exported, schema), isTrue);
   });
   ```

5. **Missing Field Handling**
   ```dart
   test('handles missing optional fields gracefully', () {
     final json = {...}  // v1 export missing v2 optional fields
     final data = ExportData.fromJson(json);
     
     expect(data.firearms.first.serialNumber, isNull);
   });
   ```

### Running Tests

```bash
# All export/import tests
flutter test test/data/services/

# Specific backwards compatibility tests
flutter test test/data/services/data_import_service_test.dart --name "v1"

# Schema validation tests
flutter test test/data/models/export_data_test.dart
```

### Creating Test Fixtures

1. **Generate from real app**:
   ```dart
   // In debug build, add code to save export JSON
   final exportData = await exportService.exportData();
   final file = File('test/fixtures/export_v2_sample.json');
   await file.writeAsString(exportData.toJsonString());
   ```

2. **Manually craft minimal examples**:
   ```json
   {
     "schemaVersion": 1,
     "exportedAt": "2026-01-01T00:00:00Z",
     "appVersion": "1.0.0",
     "metadata": {...},
     "firearms": [{...}],
     "loadRecipes": [],
     "rangeSessions": [],
     "targets": [],
     "shotVelocities": []
   }
   ```

3. **Document fixtures** in `test/fixtures/README.md`:
   ```markdown
   # Test Fixtures
   
   ## export_v1_sample.json
   - Schema version: 1
   - Contains: 2 firearms, 1 load recipe, 1 session
   - Images: No
   - Purpose: Basic v1 import test
   ```

---

## Examples & Scenarios

### Example 1: Adding Optional Field (Non-Breaking)

**Scenario**: Add `serialNumber` field to `FirearmExport`

**Changes**:
```dart
// 1. Update model
class FirearmExport {
  final String? serialNumber;  // NEW
  
  FirearmExport({
    // ... existing ...
    this.serialNumber,
  });
  
  Map<String, dynamic> toJson() {
    return {
      // ... existing ...
      'serialNumber': serialNumber,
    };
  }
  
  factory FirearmExport.fromJson(Map<String, dynamic> json) {
    return FirearmExport(
      // ... existing ...
      serialNumber: json['serialNumber'] as String?,
    );
  }
}
```

**Schema Update** (`schemas/export_v1.json`):
```json
{
  "definitions": {
    "firearm": {
      "properties": {
        "serialNumber": {
          "type": ["string", "null"],
          "description": "Optional firearm serial number"
        }
      }
    }
  }
}
```

**Tests**:
```dart
test('imports old export without serialNumber', () {
  final oldExport = loadFixture('export_v1_no_serial.json');
  final data = ExportData.fromJsonString(oldExport);
  
  expect(data.firearms.first.serialNumber, isNull);
});

test('exports and imports with serialNumber', () {
  final firearm = Firearm(serialNumber: 'ABC123', ...);
  // ... export and import ...
  expect(imported.serialNumber, 'ABC123');
});
```

**Version Change**: None (non-breaking)

---

### Example 2: Renaming Field (Breaking)

**Scenario**: Rename `model` to `modelNumber` in `FirearmExport`

**Changes**:
```dart
// 1. Increment version
const int currentExportSchemaVersion = 2;  // Was 1

// 2. Update model
class FirearmExport {
  final String modelNumber;  // Was 'model'
  
  Map<String, dynamic> toJson() {
    return {
      // ... existing ...
      'modelNumber': modelNumber,  // Changed
    };
  }
  
  factory FirearmExport.fromJson(Map<String, dynamic> json) {
    return FirearmExport(
      // ... existing ...
      modelNumber: json['modelNumber'] as String,  // Changed
    );
  }
}
```

**Migration** (`lib/data/services/data_migrator.dart`):
```dart
static Map<String, dynamic> _migrateV1ToV2Json(Map<String, dynamic> json) {
  final migrated = Map<String, dynamic>.from(json);
  
  if (migrated.containsKey('firearms')) {
    migrated['firearms'] = (migrated['firearms'] as List).map((f) {
      final firearm = Map<String, dynamic>.from(f);
      firearm['modelNumber'] = firearm.remove('model');
      return firearm;
    }).toList();
  }
  
  migrated['schemaVersion'] = 2;
  return migrated;
}
```

**New Schema** (`schemas/export_v2.json`):
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Reloading Companion Export Format v2",
  "properties": {
    "schemaVersion": {
      "const": 2
    }
  },
  "definitions": {
    "firearm": {
      "properties": {
        "modelNumber": {
          "type": "string",
          "description": "Model name/number (renamed from 'model' in v1)"
        }
      }
    }
  }
}
```

**Tests**:
```dart
test('migrates v1 to v2 - renames model field', () {
  final v1Json = {
    'schemaVersion': 1,
    // ...
    'firearms': [
      {'id': '123', 'model': 'Model 70', ...}
    ]
  };
  
  final migrated = DataMigrator.migrate(v1Json);
  
  expect(migrated.schemaVersion, 2);
  expect(migrated.firearms.first.modelNumber, 'Model 70');
});

test('imports real v1 backup file', () async {
  final v1Backup = loadFixture('export_v1_full.zip');
  final result = await importService.importData(v1Backup, ImportMode.replace);
  
  expect(result.success, true);
  expect(result.firearmsImported, greaterThan(0));
});
```

**Documentation**: Update this guide with migration details

---

### Example 3: Adding New Entity Type (Non-Breaking)

**Scenario**: Add `AccessoryExport` entity type

**Changes**:
```dart
// 1. Create new export model
class AccessoryExport {
  final String id;
  final String name;
  // ... fields ...
  
  Map<String, dynamic> toJson() { ... }
  factory AccessoryExport.fromJson(Map<String, dynamic> json) { ... }
}

// 2. Add to ExportData
class ExportData {
  // ... existing ...
  final List<AccessoryExport> accessories;  // NEW
  
  ExportData({
    // ... existing ...
    required this.accessories,
  });
  
  Map<String, dynamic> toJson() {
    return {
      // ... existing ...
      'accessories': accessories.map((a) => a.toJson()).toList(),
    };
  }
  
  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      // ... existing ...
      accessories: (json['accessories'] as List? ?? [])
          .map((a) => AccessoryExport.fromJson(a))
          .toList(),
    );
  }
}

// 3. Update metadata
class ExportMetadata {
  final int totalAccessories;  // NEW
}
```

**Schema Update** (`schemas/export_v1.json`):
```json
{
  "properties": {
    "accessories": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/accessory"
      },
      "description": "Array of exported accessories (added in app v1.1)"
    }
  },
  "definitions": {
    "accessory": {
      "type": "object",
      "required": ["id", "name", ...],
      "properties": { ... }
    }
  }
}
```

**Tests**:
```dart
test('imports old export without accessories', () {
  final oldExport = loadFixture('export_v1_no_accessories.json');
  final data = ExportData.fromJsonString(oldExport);
  
  expect(data.accessories, isEmpty);
});

test('exports and imports with accessories', () {
  // ... export with accessories ...
  expect(imported.accessories.length, 2);
});
```

**Version Change**: None (non-breaking - old exports handle missing array gracefully)

---

## Best Practices Summary

### DO ✅

- **Always** add new fields as optional (`Type?`)
- **Always** provide default values in `fromJson()` for missing fields
- **Always** increment `schemaVersion` for breaking changes
- **Always** implement and test migration logic
- **Always** maintain old schema files as documentation
- **Always** test with real exported backups, not just unit tests
- **Always** document changes in this guide
- **Always** consider user impact before making breaking changes

### DON'T ❌

- **Never** remove fields without migration
- **Never** rename fields without migration
- **Never** change field types without migration
- **Never** make optional fields required without migration
- **Never** increment `minCompatibleSchemaVersion` unless absolutely necessary
- **Never** ship breaking changes without testing real v{N-1} imports
- **Never** assume users upgrade immediately
- **Never** delete old schema files
- **Never** skip writing migration tests

---

## FAQ

**Q: How long should we support old schema versions?**

A: Indefinitely if possible. Storage is cheap, backwards compatibility is valuable. Only increment `minCompatibleSchemaVersion` if supporting old versions becomes technically infeasible (e.g., security issues, critical data model changes).

**Q: Can we make a "soft breaking" change without incrementing version?**

A: No. If old exports won't import correctly, it's breaking. There's no such thing as "soft breaking."

**Q: What if we need to fix a bug in export format?**

A: If the fix changes structure → breaking. If the fix only corrects values → non-breaking. Example: Fixing incorrect MOA calculation is non-breaking; changing MOA field from `double` to `String` is breaking.

**Q: Should we validate imported JSON against the schema at runtime?**

A: In debug builds and tests, yes. In production, validation adds overhead but catches corrupted files. Decision: Validate in debug + tests (Option A from implementation plan).

**Q: What if a user manually edits the JSON file?**

A: Schema validation will catch this. Show clear error message. Don't try to "fix" manually edited files automatically.

**Q: Can we use this migration framework for database schema changes too?**

A: No, this is specifically for export/import format. Database migrations are handled separately in `app_database.dart` using Drift's migration system.

---

## Version History

### Version 1 (Current)
- **Date**: 2026-04-21
- **Description**: Initial export format
- **Entities**: Firearm, LoadRecipe, RangeSession, Target, ShotVelocity
- **Schema**: [`schemas/export_v1.json`](schemas/export_v1.json)
- **Breaking Changes**: N/A (initial version)

### Future Versions

_When v2 is released, document changes here_

---

## Related Documentation

- [JSON Schema Definition](schemas/export_v1.json)
- [Copilot Custom Instructions](.github/copilot-instructions.md)
- [Export Service Implementation](lib/data/services/data_export_service.dart)
- [Import Service Implementation](lib/data/services/data_import_service.dart)
- [Data Migrator](lib/data/services/data_migrator.dart)
- [Export Data Models](lib/data/models/export_data.dart)

---

**Remember: User data is sacred. When in doubt, version up and migrate. Never compromise backwards compatibility.**
