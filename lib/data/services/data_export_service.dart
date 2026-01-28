import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../models/export_data.dart';
import '../datasources/firearm_local_datasource.dart';
import '../datasources/load_recipe_local_datasource.dart';
import '../datasources/range_session_local_datasource.dart';
import '../datasources/target_local_datasource.dart';
import '../datasources/shot_velocity_local_datasource.dart';
import '../../domain/entities/target.dart';

/// Service for exporting app data to a ZIP archive
class DataExportService {
  final FirearmLocalDataSource firearmDataSource;
  final LoadRecipeLocalDataSource loadRecipeDataSource;
  final RangeSessionLocalDataSource rangeSessionDataSource;
  final TargetLocalDataSource targetDataSource;
  final ShotVelocityLocalDataSource shotVelocityDataSource;

  DataExportService({
    required this.firearmDataSource,
    required this.loadRecipeDataSource,
    required this.rangeSessionDataSource,
    required this.targetDataSource,
    required this.shotVelocityDataSource,
  });

  /// Export all data to a ZIP file and share it
  /// Returns a stream of progress updates
  Stream<ExportImportProgress> exportData() async* {
    yield ExportImportProgress(
      stage: 'Preparing export...',
      current: 0,
      total: 100,
    );

    try {
      // Step 1: Gather all data from database
      yield ExportImportProgress(
        stage: 'Loading firearms...',
        current: 5,
        total: 100,
      );
      final firearms = await firearmDataSource.getAllFirearms();

      yield ExportImportProgress(
        stage: 'Loading load recipes...',
        current: 15,
        total: 100,
      );
      final loadRecipes = await loadRecipeDataSource.getAllLoadRecipes();

      yield ExportImportProgress(
        stage: 'Loading range sessions...',
        current: 25,
        total: 100,
      );
      final rangeSessions = await rangeSessionDataSource.getAllRangeSessions();

      yield ExportImportProgress(
        stage: 'Loading targets...',
        current: 35,
        total: 100,
      );
      final List<Target> allTargets = [];
      for (final session in rangeSessions) {
        final targets = await targetDataSource.getTargetsByRangeSessionId(
          session.id,
        );
        allTargets.addAll(targets);
      }

      yield ExportImportProgress(
        stage: 'Loading shot velocities...',
        current: 45,
        total: 100,
      );
      final List<dynamic> allShotVelocities = [];
      for (final target in allTargets) {
        final shots = await shotVelocityDataSource.getShotVelocitiesByTargetId(
          target.id,
        );
        allShotVelocities.addAll(shots);
      }

      // Step 2: Create temp directory for archive contents
      yield ExportImportProgress(
        stage: 'Preparing files...',
        current: 50,
        total: 100,
      );
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(
        '${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}',
      );
      await exportDir.create(recursive: true);

      final imagesDir = Directory('${exportDir.path}/images');
      await imagesDir.create(recursive: true);

      // Step 3: Copy images and build manifest
      yield ExportImportProgress(
        stage: 'Copying images...',
        current: 55,
        total: 100,
      );
      final imageManifest = <String, String>{};
      int imageCount = 0;

      // Process firearm images
      final firearmExports = <FirearmExport>[];
      for (final firearm in firearms) {
        String? imageFileName;
        if (firearm.photoPath != null && firearm.photoPath!.isNotEmpty) {
          final sourceFile = File(firearm.photoPath!);
          if (await sourceFile.exists()) {
            final ext = path.extension(firearm.photoPath!);
            imageFileName = 'firearm_${firearm.id}$ext';
            final destPath = '${imagesDir.path}/$imageFileName';
            await sourceFile.copy(destPath);
            imageManifest[firearm.id] = 'images/$imageFileName';
            imageCount++;
          }
        }
        firearmExports.add(
          FirearmExport.fromEntity(firearm, imageFileName: imageFileName),
        );
      }

      // Process target images
      yield ExportImportProgress(
        stage: 'Copying target images...',
        current: 65,
        total: 100,
      );
      final targetExports = <TargetExport>[];
      for (final target in allTargets) {
        String? imageFileName;
        if (target.photoPath != null && target.photoPath!.isNotEmpty) {
          final sourceFile = File(target.photoPath!);
          if (await sourceFile.exists()) {
            final ext = path.extension(target.photoPath!);
            imageFileName = 'target_${target.id}$ext';
            final destPath = '${imagesDir.path}/$imageFileName';
            await sourceFile.copy(destPath);
            imageManifest[target.id] = 'images/$imageFileName';
            imageCount++;
          }
        }
        targetExports.add(
          TargetExport.fromEntity(target, imageFileName: imageFileName),
        );
      }

      // Step 4: Create export data structure
      yield ExportImportProgress(
        stage: 'Creating export file...',
        current: 75,
        total: 100,
      );
      final packageInfo = await PackageInfo.fromPlatform();

      final exportData = ExportData(
        schemaVersion: currentExportSchemaVersion,
        exportedAt: DateTime.now(),
        appVersion: packageInfo.version,
        metadata: ExportMetadata(
          totalFirearms: firearms.length,
          totalLoadRecipes: loadRecipes.length,
          totalRangeSessions: rangeSessions.length,
          totalTargets: allTargets.length,
          totalShotVelocities: allShotVelocities.length,
          totalImages: imageCount,
          imageManifest: imageManifest,
        ),
        firearms: firearmExports,
        loadRecipes: loadRecipes
            .map((r) => LoadRecipeExport.fromEntity(r))
            .toList(),
        rangeSessions: rangeSessions
            .map((s) => RangeSessionExport.fromEntity(s))
            .toList(),
        targets: targetExports,
        shotVelocities: allShotVelocities
            .map((s) => ShotVelocityExport.fromEntity(s))
            .toList(),
      );

      // Step 5: Write JSON file
      final jsonFile = File('${exportDir.path}/data.json');
      await jsonFile.writeAsString(exportData.toJsonString());

      // Step 6: Create ZIP archive
      yield ExportImportProgress(
        stage: 'Creating ZIP archive...',
        current: 85,
        total: 100,
      );
      final archive = Archive();

      // Add JSON file to archive
      final jsonBytes = await jsonFile.readAsBytes();
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // Add all images to archive
      final imageFiles = imagesDir.listSync();
      for (final entity in imageFiles) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          final relativePath = 'images/${path.basename(entity.path)}';
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }

      // Encode archive to ZIP
      final zipData = ZipEncoder().encode(archive);

      // Save ZIP file
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final zipFileName = 'reloading_companion_backup_$timestamp.zip';
      final zipFile = File('${tempDir.path}/$zipFileName');
      await zipFile.writeAsBytes(zipData);

      // Step 7: Share the file
      yield ExportImportProgress(
        stage: 'Opening share dialog...',
        current: 95,
        total: 100,
      );
      await Share.shareXFiles(
        [XFile(zipFile.path)],
        subject: 'Reloading Companion Backup',
        text: 'Backup created on ${DateTime.now().toLocal()}',
      );

      // Cleanup temp directory
      await exportDir.delete(recursive: true);

      yield ExportImportProgress(
        stage: 'Export complete!',
        current: 100,
        total: 100,
      );
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Get a summary of data that will be exported (for preview)
  Future<ExportMetadata> getExportPreview() async {
    final firearms = await firearmDataSource.getAllFirearms();
    final loadRecipes = await loadRecipeDataSource.getAllLoadRecipes();
    final rangeSessions = await rangeSessionDataSource.getAllRangeSessions();

    int totalTargets = 0;
    int totalShotVelocities = 0;
    int totalImages = 0;

    for (final session in rangeSessions) {
      final targets = await targetDataSource.getTargetsByRangeSessionId(
        session.id,
      );
      totalTargets += targets.length;

      for (final target in targets) {
        final shots = await shotVelocityDataSource.getShotVelocitiesByTargetId(
          target.id,
        );
        totalShotVelocities += shots.length;

        if (target.photoPath != null && target.photoPath!.isNotEmpty) {
          final file = File(target.photoPath!);
          if (await file.exists()) {
            totalImages++;
          }
        }
      }
    }

    for (final firearm in firearms) {
      if (firearm.photoPath != null && firearm.photoPath!.isNotEmpty) {
        final file = File(firearm.photoPath!);
        if (await file.exists()) {
          totalImages++;
        }
      }
    }

    return ExportMetadata(
      totalFirearms: firearms.length,
      totalLoadRecipes: loadRecipes.length,
      totalRangeSessions: rangeSessions.length,
      totalTargets: totalTargets,
      totalShotVelocities: totalShotVelocities,
      totalImages: totalImages,
      imageManifest: {},
    );
  }
}
