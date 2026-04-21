import 'package:flutter_test/flutter_test.dart';
import 'package:workspace/data/models/export_data.dart';
import 'package:workspace/data/services/data_migrator.dart';

void main() {
  group('DataMigrator', () {
    group('migrate', () {
      test('returns data unchanged when already at current version', () {
        final json = {
          'schemaVersion': currentExportSchemaVersion,
          'exportedAt': '2026-04-21T10:00:00Z',
          'appVersion': '1.0.0',
          'metadata': {
            'totalFirearms': 0,
            'totalLoadRecipes': 0,
            'totalRangeSessions': 0,
            'totalTargets': 0,
            'totalShotVelocities': 0,
            'totalImages': 0,
            'imageManifest': <String, String>{},
          },
          'firearms': <Map<String, dynamic>>[],
          'loadRecipes': <Map<String, dynamic>>[],
          'rangeSessions': <Map<String, dynamic>>[],
          'targets': <Map<String, dynamic>>[],
          'shotVelocities': <Map<String, dynamic>>[],
        };

        final result = DataMigrator.migrate(json);

        expect(result.schemaVersion, currentExportSchemaVersion);
        expect(result.firearms, isEmpty);
      });

      test('throws UnsupportedSchemaVersionException for future version', () {
        final json = {
          'schemaVersion': currentExportSchemaVersion + 1,
          'exportedAt': '2026-04-21T10:00:00Z',
          'appVersion': '2.0.0',
        };

        expect(
          () => DataMigrator.migrate(json),
          throwsA(isA<UnsupportedSchemaVersionException>()),
        );
      });

      test('throws UnsupportedSchemaVersionException for too old version', () {
        final json = {
          'schemaVersion': minCompatibleSchemaVersion - 1,
          'exportedAt': '2026-04-21T10:00:00Z',
          'appVersion': '0.1.0',
        };

        expect(
          () => DataMigrator.migrate(json),
          throwsA(isA<UnsupportedSchemaVersionException>()),
        );
      });

      // When v2 is implemented, add migration tests:
      // test('migrates v1 to v2 correctly', () {
      //   final v1Json = {
      //     'schemaVersion': 1,
      //     'exportedAt': '2026-04-21T10:00:00Z',
      //     'appVersion': '1.0.0',
      //     'metadata': {...},
      //     'firearms': [
      //       {
      //         'id': '123',
      //         'name': 'Test Rifle',
      //         'model': 'Model 70',  // This field gets renamed in v2
      //         ...
      //       }
      //     ],
      //     ...
      //   };
      //
      //   final result = DataMigrator.migrate(v1Json);
      //
      //   expect(result.schemaVersion, 2);
      //   expect(result.firearms.first.modelNumber, 'Model 70');
      // });
    });

    group('validateMigrated', () {
      test('passes for valid data', () {
        final exportData = ExportData(
          schemaVersion: currentExportSchemaVersion,
          exportedAt: DateTime.parse('2026-04-21T10:00:00Z'),
          appVersion: '1.0.0',
          metadata: ExportMetadata(
            totalFirearms: 1,
            totalLoadRecipes: 1,
            totalRangeSessions: 1,
            totalTargets: 1,
            totalShotVelocities: 1,
            totalImages: 0,
            imageManifest: {},
          ),
          firearms: [
            FirearmExport(
              id: 'firearm-1',
              name: 'Test Rifle',
              make: 'Test',
              model: 'Model 1',
              caliber: '.308',
              barrelLength: 24.0,
              barrelTwistRate: '1:10',
              roundCount: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          loadRecipes: [
            LoadRecipeExport(
              id: 'recipe-1',
              nickname: 'Test Load',
              cartridge: '.308 Win',
              bulletWeight: 168.0,
              bulletType: 'HPBT',
              powderType: 'Varget',
              powderCharge: 44.0,
              primerType: 'CCI BR-2',
              brassType: 'Lapua',
              coalLength: 2.800,
              pressureSigns: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          rangeSessions: [
            RangeSessionExport(
              id: 'session-1',
              date: DateTime.now(),
              firearmId: 'firearm-1',
              loadRecipeId: 'recipe-1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          targets: [
            TargetExport(
              id: 'target-1',
              rangeSessionId: 'session-1',
              distance: 100.0,
              numberOfShots: 5,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          shotVelocities: [
            ShotVelocityExport(
              id: 'shot-1',
              targetId: 'target-1',
              velocity: 2700.0,
              timestamp: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        );

        expect(
          () => DataMigrator.validateMigrated(exportData),
          returnsNormally,
        );
      });

      test('throws for incorrect schema version', () {
        final exportData = ExportData(
          schemaVersion: currentExportSchemaVersion - 1,
          exportedAt: DateTime.parse('2026-04-21T10:00:00Z'),
          appVersion: '1.0.0',
          metadata: ExportMetadata(
            totalFirearms: 0,
            totalLoadRecipes: 0,
            totalRangeSessions: 0,
            totalTargets: 0,
            totalShotVelocities: 0,
            totalImages: 0,
            imageManifest: {},
          ),
          firearms: [],
          loadRecipes: [],
          rangeSessions: [],
          targets: [],
          shotVelocities: [],
        );

        expect(
          () => DataMigrator.validateMigrated(exportData),
          throwsA(isA<MigrationValidationException>()),
        );
      });

      test('throws for invalid firearm reference in range session', () {
        final exportData = ExportData(
          schemaVersion: currentExportSchemaVersion,
          exportedAt: DateTime.parse('2026-04-21T10:00:00Z'),
          appVersion: '1.0.0',
          metadata: ExportMetadata(
            totalFirearms: 0,
            totalLoadRecipes: 1,
            totalRangeSessions: 1,
            totalTargets: 0,
            totalShotVelocities: 0,
            totalImages: 0,
            imageManifest: {},
          ),
          firearms: [],
          loadRecipes: [
            LoadRecipeExport(
              id: 'recipe-1',
              nickname: 'Test Load',
              cartridge: '.308 Win',
              bulletWeight: 168.0,
              bulletType: 'HPBT',
              powderType: 'Varget',
              powderCharge: 44.0,
              primerType: 'CCI BR-2',
              brassType: 'Lapua',
              coalLength: 2.800,
              pressureSigns: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          rangeSessions: [
            RangeSessionExport(
              id: 'session-1',
              date: DateTime.now(),
              firearmId: 'nonexistent-firearm', // Invalid reference
              loadRecipeId: 'recipe-1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          targets: [],
          shotVelocities: [],
        );

        expect(
          () => DataMigrator.validateMigrated(exportData),
          throwsA(isA<MigrationValidationException>()),
        );
      });

      test('throws for invalid target reference in shot velocity', () {
        final exportData = ExportData(
          schemaVersion: currentExportSchemaVersion,
          exportedAt: DateTime.parse('2026-04-21T10:00:00Z'),
          appVersion: '1.0.0',
          metadata: ExportMetadata(
            totalFirearms: 0,
            totalLoadRecipes: 0,
            totalRangeSessions: 0,
            totalTargets: 0,
            totalShotVelocities: 1,
            totalImages: 0,
            imageManifest: {},
          ),
          firearms: [],
          loadRecipes: [],
          rangeSessions: [],
          targets: [],
          shotVelocities: [
            ShotVelocityExport(
              id: 'shot-1',
              targetId: 'nonexistent-target', // Invalid reference
              velocity: 2700.0,
              timestamp: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        );

        expect(
          () => DataMigrator.validateMigrated(exportData),
          throwsA(isA<MigrationValidationException>()),
        );
      });
    });

    group('getMigrationDescription', () {
      test('returns no migration needed for same version', () {
        final description = DataMigrator.getMigrationDescription(1, 1);
        expect(description, contains('No migration needed'));
      });

      test('returns migration description for different versions', () {
        final description = DataMigrator.getMigrationDescription(1, 2);
        expect(description, contains('Migrate v1'));
        expect(description, contains('v2'));
      });
    });
  });
}
