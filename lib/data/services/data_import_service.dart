import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

import '../models/export_data.dart';
import '../models/app_database.dart';
import '../datasources/firearm_local_datasource.dart';
import '../datasources/load_recipe_local_datasource.dart';
import '../datasources/range_session_local_datasource.dart';
import '../datasources/target_local_datasource.dart';
import '../datasources/shot_velocity_local_datasource.dart';

/// Service for importing app data from a ZIP archive
class DataImportService {
  final AppDatabase database;
  final FirearmLocalDataSource firearmDataSource;
  final LoadRecipeLocalDataSource loadRecipeDataSource;
  final RangeSessionLocalDataSource rangeSessionDataSource;
  final TargetLocalDataSource targetDataSource;
  final ShotVelocityLocalDataSource shotVelocityDataSource;

  DataImportService({
    required this.database,
    required this.firearmDataSource,
    required this.loadRecipeDataSource,
    required this.rangeSessionDataSource,
    required this.targetDataSource,
    required this.shotVelocityDataSource,
  });

  /// Pick a backup file using the system file picker
  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.first.path;
    }
    return null;
  }

  /// Validate an import file without actually importing
  /// Returns metadata if valid, throws exception if invalid
  Future<ImportValidationResult> validateImportFile(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw Exception('File not found: $zipPath');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find data.json
    final dataJsonFile = archive.files.firstWhere(
      (f) => f.name == 'data.json',
      orElse: () => throw Exception('Invalid backup file: missing data.json'),
    );

    final jsonContent = String.fromCharCodes(dataJsonFile.content as List<int>);
    final exportData = ExportData.fromJsonString(jsonContent);

    // Check schema version
    if (exportData.schemaVersion > currentExportSchemaVersion) {
      throw Exception(
        'This backup was created with a newer version of the app (schema v${exportData.schemaVersion}). '
        'Please update the app to import this backup.',
      );
    }

    if (exportData.schemaVersion < minCompatibleSchemaVersion) {
      throw Exception(
        'This backup is too old (schema v${exportData.schemaVersion}) and cannot be imported. '
        'Minimum supported version is v$minCompatibleSchemaVersion.',
      );
    }

    // Count images in archive
    final imageCount = archive.files
        .where((f) => f.name.startsWith('images/'))
        .length;

    return ImportValidationResult(
      isValid: true,
      schemaVersion: exportData.schemaVersion,
      exportedAt: exportData.exportedAt,
      appVersion: exportData.appVersion,
      metadata: exportData.metadata,
      needsMigration: exportData.schemaVersion < currentExportSchemaVersion,
      imageCount: imageCount,
    );
  }

  /// Import data from a ZIP file
  /// Returns a stream of progress updates with final result
  Stream<ImportProgressUpdate> importData(
    String zipPath,
    ImportMode mode,
  ) async* {
    yield ImportProgressUpdate(
      progress: ExportImportProgress(
        stage: 'Preparing import...',
        current: 0,
        total: 100,
      ),
    );

    try {
      // Step 1: Extract and parse ZIP
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Reading backup file...',
          current: 5,
          total: 100,
        ),
      );

      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Step 2: Parse JSON data
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Parsing data...',
          current: 10,
          total: 100,
        ),
      );

      final dataJsonFile = archive.files.firstWhere(
        (f) => f.name == 'data.json',
      );
      final jsonContent = String.fromCharCodes(
        dataJsonFile.content as List<int>,
      );
      final exportData = ExportData.fromJsonString(jsonContent);

      // Step 3: Extract images to temp directory
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Extracting images...',
          current: 15,
          total: 100,
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(
        '${tempDir.path}/import_${DateTime.now().millisecondsSinceEpoch}',
      );
      await extractDir.create(recursive: true);

      final extractedImages =
          <String, String>{}; // Maps archive path to extracted path
      for (final file in archive.files) {
        if (file.name.startsWith('images/') && file.isFile) {
          final extractPath = '${extractDir.path}/${file.name}';
          final extractFile = File(extractPath);
          await extractFile.parent.create(recursive: true);
          await extractFile.writeAsBytes(file.content as List<int>);
          extractedImages[file.name] = extractPath;
        }
      }

      // Step 4: If replace mode, clear existing data
      if (mode == ImportMode.replace) {
        yield ImportProgressUpdate(
          progress: ExportImportProgress(
            stage: 'Clearing existing data...',
            current: 20,
            total: 100,
          ),
        );
        await _clearAllData();
      }

      // Step 5: Get existing IDs for merge mode
      final existingFirearmIds = <String>{};
      final existingLoadRecipeIds = <String>{};
      final existingRangeSessionIds = <String>{};
      final existingTargetIds = <String>{};
      final existingShotVelocityIds = <String>{};

      if (mode == ImportMode.merge) {
        yield ImportProgressUpdate(
          progress: ExportImportProgress(
            stage: 'Checking existing data...',
            current: 25,
            total: 100,
          ),
        );

        final firearms = await firearmDataSource.getAllFirearms();
        existingFirearmIds.addAll(firearms.map((f) => f.id));

        final loadRecipes = await loadRecipeDataSource.getAllLoadRecipes();
        existingLoadRecipeIds.addAll(loadRecipes.map((l) => l.id));

        final rangeSessions = await rangeSessionDataSource
            .getAllRangeSessions();
        existingRangeSessionIds.addAll(rangeSessions.map((r) => r.id));

        for (final session in rangeSessions) {
          final targets = await targetDataSource.getTargetsByRangeSessionId(
            session.id,
          );
          existingTargetIds.addAll(targets.map((t) => t.id));

          for (final target in targets) {
            final shots = await shotVelocityDataSource
                .getShotVelocitiesByTargetId(target.id);
            existingShotVelocityIds.addAll(shots.map((s) => s.id));
          }
        }
      }

      // Step 6: Import firearms
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Importing firearms...',
          current: 30,
          total: 100,
        ),
      );

      int firearmsImported = 0;
      int firearmsSkipped = 0;
      final appDir = await getApplicationDocumentsDirectory();
      final firearmPhotosDir = Directory('${appDir.path}/firearm_photos');
      await firearmPhotosDir.create(recursive: true);

      for (final firearmExport in exportData.firearms) {
        if (mode == ImportMode.merge &&
            existingFirearmIds.contains(firearmExport.id)) {
          firearmsSkipped++;
          continue;
        }

        String? photoPath;
        if (firearmExport.imageFileName != null) {
          final archivePath = 'images/${firearmExport.imageFileName}';
          final extractedPath = extractedImages[archivePath];
          if (extractedPath != null) {
            final ext = p.extension(extractedPath);
            final destPath = '${firearmPhotosDir.path}/${firearmExport.id}$ext';
            await File(extractedPath).copy(destPath);
            photoPath = destPath;
          }
        }

        final firearm = firearmExport.toEntity(photoPath: photoPath);
        await firearmDataSource.addFirearm(firearm);
        firearmsImported++;
      }

      // Step 7: Import load recipes
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Importing load recipes...',
          current: 45,
          total: 100,
        ),
      );

      int loadRecipesImported = 0;
      int loadRecipesSkipped = 0;

      for (final recipeExport in exportData.loadRecipes) {
        if (mode == ImportMode.merge &&
            existingLoadRecipeIds.contains(recipeExport.id)) {
          loadRecipesSkipped++;
          continue;
        }

        final recipe = recipeExport.toEntity();
        await loadRecipeDataSource.addLoadRecipe(recipe);
        loadRecipesImported++;
      }

      // Step 8: Import range sessions
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Importing range sessions...',
          current: 60,
          total: 100,
        ),
      );

      int rangeSessionsImported = 0;
      int rangeSessionsSkipped = 0;

      for (final sessionExport in exportData.rangeSessions) {
        if (mode == ImportMode.merge &&
            existingRangeSessionIds.contains(sessionExport.id)) {
          rangeSessionsSkipped++;
          continue;
        }

        // Check if referenced firearm and load recipe exist
        final firearmExists =
            existingFirearmIds.contains(sessionExport.firearmId) ||
            exportData.firearms.any((f) => f.id == sessionExport.firearmId);
        final loadRecipeExists =
            existingLoadRecipeIds.contains(sessionExport.loadRecipeId) ||
            exportData.loadRecipes.any(
              (l) => l.id == sessionExport.loadRecipeId,
            );

        if (!firearmExists || !loadRecipeExists) {
          rangeSessionsSkipped++;
          continue;
        }

        final session = sessionExport.toEntity();
        await rangeSessionDataSource.addRangeSession(session);
        rangeSessionsImported++;
      }

      // Step 9: Import targets
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Importing targets...',
          current: 75,
          total: 100,
        ),
      );

      int targetsImported = 0;
      int targetsSkipped = 0;
      int imagesImported = 0;
      final targetPhotosDir = Directory('${appDir.path}/target_photos');
      await targetPhotosDir.create(recursive: true);

      for (final targetExport in exportData.targets) {
        if (mode == ImportMode.merge &&
            existingTargetIds.contains(targetExport.id)) {
          targetsSkipped++;
          continue;
        }

        // Check if referenced range session exists
        final sessionExists =
            existingRangeSessionIds.contains(targetExport.rangeSessionId) ||
            (rangeSessionsImported > 0 &&
                exportData.rangeSessions.any(
                  (s) => s.id == targetExport.rangeSessionId,
                ));

        if (!sessionExists && mode == ImportMode.merge) {
          targetsSkipped++;
          continue;
        }

        String? photoPath;
        if (targetExport.imageFileName != null) {
          final archivePath = 'images/${targetExport.imageFileName}';
          final extractedPath = extractedImages[archivePath];
          if (extractedPath != null) {
            final ext = p.extension(extractedPath);
            final destPath = '${targetPhotosDir.path}/${targetExport.id}$ext';
            await File(extractedPath).copy(destPath);
            photoPath = destPath;
            imagesImported++;
          }
        }

        final target = targetExport.toEntity(photoPath: photoPath);
        await targetDataSource.addTarget(target);
        targetsImported++;
      }

      // Step 10: Import shot velocities
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Importing shot velocities...',
          current: 90,
          total: 100,
        ),
      );

      int shotVelocitiesImported = 0;
      int shotVelocitiesSkipped = 0;

      for (final shotExport in exportData.shotVelocities) {
        if (mode == ImportMode.merge &&
            existingShotVelocityIds.contains(shotExport.id)) {
          shotVelocitiesSkipped++;
          continue;
        }

        // Check if referenced target exists
        final targetExists =
            existingTargetIds.contains(shotExport.targetId) ||
            (targetsImported > 0 &&
                exportData.targets.any((t) => t.id == shotExport.targetId));

        if (!targetExists && mode == ImportMode.merge) {
          shotVelocitiesSkipped++;
          continue;
        }

        final shot = shotExport.toEntity();
        await shotVelocityDataSource.addShotVelocity(shot);
        shotVelocitiesImported++;
      }

      // Cleanup temp directory
      await extractDir.delete(recursive: true);

      // Final result
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Import complete!',
          current: 100,
          total: 100,
        ),
        result: ImportResult(
          success: true,
          firearmsImported: firearmsImported,
          firearmsSkipped: firearmsSkipped,
          loadRecipesImported: loadRecipesImported,
          loadRecipesSkipped: loadRecipesSkipped,
          rangeSessionsImported: rangeSessionsImported,
          rangeSessionsSkipped: rangeSessionsSkipped,
          targetsImported: targetsImported,
          targetsSkipped: targetsSkipped,
          shotVelocitiesImported: shotVelocitiesImported,
          shotVelocitiesSkipped: shotVelocitiesSkipped,
          imagesImported: imagesImported,
        ),
      );
    } catch (e) {
      yield ImportProgressUpdate(
        progress: ExportImportProgress(
          stage: 'Import failed',
          current: 0,
          total: 100,
        ),
        result: ImportResult.error('Import failed: $e'),
      );
    }
  }

  /// Clear all data from the database
  Future<void> _clearAllData() async {
    // Delete in reverse order of dependencies
    await (database.delete(database.shotVelocities)).go();
    await (database.delete(database.targets)).go();
    await (database.delete(database.rangeSessions)).go();
    await (database.delete(database.loadRecipes)).go();
    await (database.delete(database.firearms)).go();

    // Also clean up image directories
    final appDir = await getApplicationDocumentsDirectory();

    final firearmPhotosDir = Directory('${appDir.path}/firearm_photos');
    if (await firearmPhotosDir.exists()) {
      await firearmPhotosDir.delete(recursive: true);
      await firearmPhotosDir.create();
    }

    final targetPhotosDir = Directory('${appDir.path}/target_photos');
    if (await targetPhotosDir.exists()) {
      await targetPhotosDir.delete(recursive: true);
      await targetPhotosDir.create();
    }
  }
}

/// Result of validating an import file
class ImportValidationResult {
  final bool isValid;
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final ExportMetadata metadata;
  final bool needsMigration;
  final int imageCount;

  ImportValidationResult({
    required this.isValid,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.metadata,
    required this.needsMigration,
    required this.imageCount,
  });
}

/// Progress update during import, may include final result
class ImportProgressUpdate {
  final ExportImportProgress progress;
  final ImportResult? result;

  ImportProgressUpdate({required this.progress, this.result});
}
