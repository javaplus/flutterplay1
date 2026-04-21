import 'package:flutter_test/flutter_test.dart';
import 'package:workspace/data/models/export_data.dart';

void main() {
  group('ExportData', () {
    test('serializes and deserializes correctly', () {
      final original = ExportData(
        schemaVersion: 1,
        exportedAt: DateTime.parse('2026-04-21T10:00:00Z'),
        appVersion: '1.0.0',
        metadata: ExportMetadata(
          totalFirearms: 1,
          totalLoadRecipes: 1,
          totalRangeSessions: 0,
          totalTargets: 0,
          totalShotVelocities: 0,
          totalImages: 0,
          imageManifest: {'firearm-1': 'images/firearm_123.jpg'},
        ),
        firearms: [
          FirearmExport(
            id: 'firearm-1',
            name: 'Test Rifle',
            make: 'Winchester',
            model: 'Model 70',
            caliber: '.308 Winchester',
            barrelLength: 24.0,
            barrelTwistRate: '1:10',
            roundCount: 500,
            opticInfo: 'Leupold VX-5HD',
            notes: 'Test notes',
            imageFileName: 'firearm_123.jpg',
            createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
            updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
          ),
        ],
        loadRecipes: [
          LoadRecipeExport(
            id: 'recipe-1',
            nickname: 'Match Load',
            cartridge: '.308 Winchester',
            bulletWeight: 168.0,
            bulletType: 'Sierra MatchKing HPBT',
            powderType: 'Varget',
            powderCharge: 44.0,
            primerType: 'CCI BR-2',
            brassType: 'Lapua',
            brassPrep: 'Full length resize',
            coalLength: 2.800,
            seatingDepth: 0.020,
            crimp: 'None',
            pressureSigns: ['Normal'],
            notes: 'Accurate load',
            createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
            updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
          ),
        ],
        rangeSessions: [],
        targets: [],
        shotVelocities: [],
      );

      final jsonString = original.toJsonString();
      final deserialized = ExportData.fromJsonString(jsonString);

      expect(deserialized.schemaVersion, original.schemaVersion);
      expect(deserialized.exportedAt, original.exportedAt);
      expect(deserialized.appVersion, original.appVersion);
      expect(deserialized.firearms.length, 1);
      expect(deserialized.firearms.first.name, 'Test Rifle');
      expect(deserialized.loadRecipes.length, 1);
      expect(deserialized.loadRecipes.first.nickname, 'Match Load');
    });

    test('toJson produces valid JSON structure', () {
      final exportData = ExportData(
        schemaVersion: 1,
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

      final json = exportData.toJson();

      expect(json['schemaVersion'], 1);
      expect(json['exportedAt'], '2026-04-21T10:00:00.000Z');
      expect(json['appVersion'], '1.0.0');
      expect(json['metadata'], isA<Map<String, dynamic>>());
      expect(json['firearms'], isA<List>());
      expect(json['loadRecipes'], isA<List>());
      expect(json['rangeSessions'], isA<List>());
      expect(json['targets'], isA<List>());
      expect(json['shotVelocities'], isA<List>());
    });
  });

  group('FirearmExport', () {
    test('serializes and deserializes correctly with all fields', () {
      final original = FirearmExport(
        id: 'test-id',
        name: 'Test Rifle',
        make: 'Winchester',
        model: 'Model 70',
        caliber: '.308 Winchester',
        barrelLength: 24.0,
        barrelTwistRate: '1:10',
        roundCount: 500,
        opticInfo: 'Leupold VX-5HD',
        notes: 'Test notes',
        imageFileName: 'firearm_123.jpg',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = FirearmExport.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.make, original.make);
      expect(deserialized.model, original.model);
      expect(deserialized.caliber, original.caliber);
      expect(deserialized.barrelLength, original.barrelLength);
      expect(deserialized.barrelTwistRate, original.barrelTwistRate);
      expect(deserialized.roundCount, original.roundCount);
      expect(deserialized.opticInfo, original.opticInfo);
      expect(deserialized.notes, original.notes);
      expect(deserialized.imageFileName, original.imageFileName);
      expect(deserialized.createdAt, original.createdAt);
      expect(deserialized.updatedAt, original.updatedAt);
    });

    test('handles null optional fields', () {
      final original = FirearmExport(
        id: 'test-id',
        name: 'Test Rifle',
        make: 'Winchester',
        model: 'Model 70',
        caliber: '.308 Winchester',
        barrelLength: 24.0,
        barrelTwistRate: '1:10',
        roundCount: 500,
        opticInfo: null,
        notes: null,
        imageFileName: null,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = FirearmExport.fromJson(json);

      expect(deserialized.opticInfo, isNull);
      expect(deserialized.notes, isNull);
      expect(deserialized.imageFileName, isNull);
    });
  });

  group('LoadRecipeExport', () {
    test('serializes and deserializes correctly', () {
      final original = LoadRecipeExport(
        id: 'recipe-1',
        nickname: 'Match Load',
        cartridge: '.308 Winchester',
        bulletWeight: 168.0,
        bulletType: 'Sierra MatchKing HPBT',
        powderType: 'Varget',
        powderCharge: 44.0,
        primerType: 'CCI BR-2',
        brassType: 'Lapua',
        brassPrep: 'Full length resize',
        coalLength: 2.800,
        seatingDepth: 0.020,
        crimp: 'None',
        pressureSigns: ['Normal', 'No issues'],
        notes: 'Accurate load',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = LoadRecipeExport.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.nickname, original.nickname);
      expect(deserialized.cartridge, original.cartridge);
      expect(deserialized.bulletWeight, original.bulletWeight);
      expect(deserialized.powderCharge, original.powderCharge);
      expect(deserialized.pressureSigns, original.pressureSigns);
    });

    test('handles empty pressure signs array', () {
      final original = LoadRecipeExport(
        id: 'recipe-1',
        nickname: 'Test Load',
        cartridge: '.308 Winchester',
        bulletWeight: 168.0,
        bulletType: 'HPBT',
        powderType: 'Varget',
        powderCharge: 44.0,
        primerType: 'CCI BR-2',
        brassType: 'Lapua',
        coalLength: 2.800,
        pressureSigns: [],
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T00:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = LoadRecipeExport.fromJson(json);

      expect(deserialized.pressureSigns, isEmpty);
    });
  });

  group('RangeSessionExport', () {
    test('serializes and deserializes correctly', () {
      final original = RangeSessionExport(
        id: 'session-1',
        date: DateTime.parse('2026-04-21T10:00:00Z'),
        firearmId: 'firearm-1',
        loadRecipeId: 'recipe-1',
        weather: 'Sunny, 70F',
        notes: 'Good session',
        createdAt: DateTime.parse('2026-04-21T10:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T12:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = RangeSessionExport.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.date, original.date);
      expect(deserialized.firearmId, original.firearmId);
      expect(deserialized.loadRecipeId, original.loadRecipeId);
      expect(deserialized.weather, original.weather);
      expect(deserialized.notes, original.notes);
    });
  });

  group('TargetExport', () {
    test('serializes and deserializes correctly', () {
      final original = TargetExport(
        id: 'target-1',
        rangeSessionId: 'session-1',
        imageFileName: 'target_123.jpg',
        distance: 100.0,
        numberOfShots: 5,
        groupSizeInches: 1.5,
        groupSizeMoa: 1.43,
        avgVelocity: 2700.0,
        standardDeviation: 12.5,
        extremeSpread: 30.0,
        notes: 'Good group',
        createdAt: DateTime.parse('2026-04-21T10:00:00Z'),
        updatedAt: DateTime.parse('2026-04-21T10:00:00Z'),
      );

      final json = original.toJson();
      final deserialized = TargetExport.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.rangeSessionId, original.rangeSessionId);
      expect(deserialized.distance, original.distance);
      expect(deserialized.numberOfShots, original.numberOfShots);
      expect(deserialized.groupSizeInches, original.groupSizeInches);
      expect(deserialized.avgVelocity, original.avgVelocity);
    });
  });

  group('ShotVelocityExport', () {
    test('serializes and deserializes correctly', () {
      final original = ShotVelocityExport(
        id: 'shot-1',
        targetId: 'target-1',
        velocity: 2700.5,
        timestamp: DateTime.parse('2026-04-21T10:30:00Z'),
        createdAt: DateTime.parse('2026-04-21T10:30:00Z'),
        updatedAt: DateTime.parse('2026-04-21T10:30:00Z'),
      );

      final json = original.toJson();
      final deserialized = ShotVelocityExport.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.targetId, original.targetId);
      expect(deserialized.velocity, original.velocity);
      expect(deserialized.timestamp, original.timestamp);
    });
  });

  group('Backwards Compatibility', () {
    test('handles missing optional fields in JSON', () {
      // Simulate an old export that's missing newer optional fields
      final json = {
        'id': 'test-id',
        'name': 'Test Rifle',
        'make': 'Winchester',
        'model': 'Model 70',
        'caliber': '.308 Winchester',
        'barrelLength': 24.0,
        'barrelTwistRate': '1:10',
        'roundCount': 500,
        // opticInfo, notes, imageFileName intentionally missing
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-04-21T00:00:00.000Z',
      };

      final firearm = FirearmExport.fromJson(json);

      expect(firearm.id, 'test-id');
      expect(firearm.name, 'Test Rifle');
      expect(firearm.opticInfo, isNull);
      expect(firearm.notes, isNull);
      expect(firearm.imageFileName, isNull);
    });

    test('handles missing nullable fields in LoadRecipeExport', () {
      final json = {
        'id': 'recipe-1',
        'nickname': 'Test Load',
        'cartridge': '.308 Winchester',
        'bulletWeight': 168.0,
        'bulletType': 'HPBT',
        'powderType': 'Varget',
        'powderCharge': 44.0,
        'primerType': 'CCI BR-2',
        'brassType': 'Lapua',
        'coalLength': 2.800,
        'pressureSigns': <String>[],
        // brassPrep, seatingDepth, crimp, notes missing
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-04-21T00:00:00.000Z',
      };

      final recipe = LoadRecipeExport.fromJson(json);

      expect(recipe.brassPrep, isNull);
      expect(recipe.seatingDepth, isNull);
      expect(recipe.crimp, isNull);
      expect(recipe.notes, isNull);
    });
  });

  group('ExportMetadata', () {
    test('serializes and deserializes correctly', () {
      final original = ExportMetadata(
        totalFirearms: 10,
        totalLoadRecipes: 15,
        totalRangeSessions: 5,
        totalTargets: 20,
        totalShotVelocities: 100,
        totalImages: 25,
        imageManifest: {
          'firearm-1': 'images/firearm_123.jpg',
          'target-1': 'images/target_456.jpg',
        },
      );

      final json = original.toJson();
      final deserialized = ExportMetadata.fromJson(json);

      expect(deserialized.totalFirearms, original.totalFirearms);
      expect(deserialized.totalLoadRecipes, original.totalLoadRecipes);
      expect(deserialized.totalImages, original.totalImages);
      expect(deserialized.imageManifest.length, 2);
    });
  });
}
