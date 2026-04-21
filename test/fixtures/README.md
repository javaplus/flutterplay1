# Test Fixtures for Export/Import

This directory contains sample export files used for backwards compatibility testing.

## Export Files

### export_v1_minimal.json
- **Schema Version**: 1
- **Contents**: Minimal valid export with empty arrays
- **Purpose**: Test basic structure validation
- **Images**: None

### export_v1_full.json
- **Schema Version**: 1
- **Contents**: Complete export with all entity types
  - 2 firearms (1 with image, 1 without)
  - 2 load recipes
  - 2 range sessions
  - 3 targets (2 with images)
  - 10 shot velocities
- **Purpose**: Comprehensive backwards compatibility testing
- **Images**: References to images (not included in JSON-only fixture)

### Future Fixtures

When breaking changes require schema v2+:

- `export_v2_sample.json` - Sample v2 export for migration testing
- `export_v1_to_v2_migration.json` - v1 export designed to test specific v2 migrations

## ZIP Archives

### export_v1_full.zip
- **Schema Version**: 1
- **Structure**:
  ```
  export_v1_full.zip
  ├── data.json
  └── images/
      ├── firearm_f1.jpg
      ├── target_t1.jpg
      └── target_t2.jpg
  ```
- **Purpose**: Full import test including image restoration

## Usage in Tests

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports v1 export', () async {
    final fixturePath = 'test/fixtures/export_v1_full.zip';
    final result = await importService.importData(fixturePath, ImportMode.replace);
    
    expect(result.success, true);
    expect(result.firearmsImported, 2);
  });
}
```

## Generating New Fixtures

To generate fixtures from the app:

1. **Run app in debug mode**
2. **Add temporary code** in export service:
   ```dart
   // In DataExportService.exportData() after creating ExportData
   final jsonFile = File('test/fixtures/export_v1_sample.json');
   await jsonFile.writeAsString(exportData.toJsonString());
   ```
3. **Export data** from the app
4. **Copy generated file** to fixtures directory
5. **Remove temporary code**
6. **Document fixture** in this README

## Guidelines

- **Never modify fixtures** after creation (they represent historical formats)
- **Always test with fixtures** before releasing breaking changes
- **Keep fixtures small** but representative
- **Document schema version** clearly
- **Include edge cases**: empty fields, null optionals, max values, etc.
