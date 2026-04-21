# GitHub Copilot Custom Instructions for Reloading Companion

## Critical: Import/Export Backwards Compatibility

**⚠️ BREAKING CHANGES TO EXPORT FORMAT ARE PROHIBITED WITHOUT PROPER VERSIONING ⚠️**

### Protected Files & Classes

The following files contain the export/import contract and must be treated with extreme caution:

- `lib/data/models/export_data.dart` - All export model classes and schema version constants
- `lib/data/services/data_export_service.dart` - Export logic
- `lib/data/services/data_import_service.dart` - Import logic and validation
- `schemas/export_v1.json` - JSON Schema defining the export format contract

### Rules for Export Model Changes

When modifying any of the following classes in `export_data.dart`:
- `ExportData`
- `ExportMetadata`
- `FirearmExport`
- `LoadRecipeExport`
- `RangeSessionExport`
- `TargetExport`
- `ShotVelocityExport`

**YOU MUST:**

1. **Determine if the change is breaking:**
   - **BREAKING**: Removing fields, renaming fields, changing field types, making optional fields required
   - **NON-BREAKING**: Adding new optional fields, adding new entity types

2. **For BREAKING changes:**
   - Increment `currentExportSchemaVersion` in `export_data.dart`
   - Create new schema file `schemas/export_v{new_version}.json`
   - Update `EXPORT_COMPATIBILITY_GUIDE.md` with migration instructions
   - Implement migration logic in `lib/data/services/data_migrator.dart`
   - Add migration tests that verify v1 → v{new_version} data transformation
   - Update `minCompatibleSchemaVersion` if old exports can no longer be imported
   - **NEVER ship breaking changes without complete migration path**

3. **For NON-BREAKING changes:**
   - Update `schemas/export_v1.json` to reflect new optional fields
   - Ensure `fromJson()` methods handle missing fields gracefully
   - Add tests verifying old exports still import correctly
   - Document changes in `EXPORT_COMPATIBILITY_GUIDE.md`

4. **Always:**
   - Update or add unit tests for modified model serialization
   - Run backwards compatibility tests: `flutter test test/data/services/data_import_service_test.dart`
   - Validate exported JSON against the schema: `flutter test test/data/models/export_data_test.dart`
   - Never use `@JsonKey(required: true)` without incrementing schema version

### Validation Requirements

Before completing any change to export models:

```bash
# 1. Run all export/import tests
flutter test test/data/services/data_export_service_test.dart
flutter test test/data/services/data_import_service_test.dart
flutter test test/data/models/export_data_test.dart

# 2. Verify backwards compatibility tests pass
flutter test test/data/services/data_import_service_test.dart --name "backwards_compatibility"

# 3. Generate a test export and validate against schema
# (Manual step - export data from app, validate JSON)
```

### Example Breaking vs Non-Breaking Changes

**✅ SAFE (Non-Breaking):**
```dart
// Adding optional field
class FirearmExport {
  final String? serialNumber;  // NEW optional field
  
  factory FirearmExport.fromJson(Map<String, dynamic> json) {
    return FirearmExport(
      // ... existing fields ...
      serialNumber: json['serialNumber'] as String?,  // Gracefully handles missing
    );
  }
}
```

**❌ BREAKING (Requires Schema Version Bump):**
```dart
// Removing a field
class FirearmExport {
  // final String model;  // ❌ REMOVED - BREAKING!
}

// Renaming a field
class FirearmExport {
  final String modelNumber;  // ❌ Was 'model' - BREAKING!
}

// Changing field type
class FirearmExport {
  final int barrelLength;  // ❌ Was 'double' - BREAKING!
}

// Making optional field required
class FirearmExport {
  final String notes;  // ❌ Was 'String?' - BREAKING!
}
```

### Schema Version Management

Current state:
- **Current Schema Version**: 1
- **Minimum Compatible Version**: 1
- **Schema Files**: `schemas/export_v1.json`

When incrementing schema version:
1. Update `currentExportSchemaVersion` constant
2. Create `schemas/export_v{N}.json` with new schema
3. Keep old schema files for reference (never delete)
4. Update migration logic to handle v{N-1} → v{N}

### Testing Checklist

Before submitting changes to export/import code:

- [ ] All existing tests pass
- [ ] Added tests for new functionality
- [ ] Backwards compatibility tests pass (can import v1 exports)
- [ ] Schema validation tests pass
- [ ] Manual test: Export from current code, import into modified code
- [ ] Manual test: Export from old version, import into new version
- [ ] Documentation updated (EXPORT_COMPATIBILITY_GUIDE.md)
- [ ] Schema file updated (or new version created)

### Emergency: If You Accidentally Made a Breaking Change

If you've already shipped a breaking change without versioning:

1. **DO NOT** just increment the version - users' backups may be corrupted
2. Add migration logic that detects the old format and migrates it
3. Add tests with sample data in both formats
4. Document the issue and resolution in EXPORT_COMPATIBILITY_GUIDE.md
5. Consider adding runtime warnings for affected users

### Questions?

When uncertain about whether a change is breaking:
- Consult `EXPORT_COMPATIBILITY_GUIDE.md`
- Ask: "Can old exported files still be imported without data loss?"
- If answer is "no" or "maybe" → it's breaking
- When in doubt, treat it as breaking and version accordingly

### Remember

**Users trust us with their reloading data. Losing a backup file due to incompatibility is unacceptable. Always err on the side of caution with versioning.**
