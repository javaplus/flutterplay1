import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/export_data.dart';
import '../../data/services/data_export_service.dart';
import '../../data/services/data_import_service.dart';
import '../../data/datasources/load_recipe_local_datasource.dart';
import '../../data/datasources/range_session_local_datasource.dart';
import '../../data/datasources/target_local_datasource.dart';
import '../../data/datasources/shot_velocity_local_datasource.dart';
import 'firearm_provider.dart';

// Re-export types needed by the settings screen
export '../../data/models/export_data.dart'
    show ExportMetadata, ExportImportProgress, ImportMode, ImportResult;
export '../../data/services/data_import_service.dart'
    show ImportValidationResult;

/// Provider for LoadRecipe local data source
final loadRecipeLocalDataSourceProvider = Provider<LoadRecipeLocalDataSource>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  return LoadRecipeLocalDataSource(database);
});

/// Provider for RangeSession local data source
final rangeSessionLocalDataSourceProvider =
    Provider<RangeSessionLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return RangeSessionLocalDataSource(database);
    });

/// Provider for Target local data source
final targetLocalDataSourceProvider = Provider<TargetLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return TargetLocalDataSource(database);
});

/// Provider for ShotVelocity local data source
final shotVelocityLocalDataSourceProvider =
    Provider<ShotVelocityLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return ShotVelocityLocalDataSource(database);
    });

/// Provider for DataExportService
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService(
    firearmDataSource: ref.watch(firearmLocalDataSourceProvider),
    loadRecipeDataSource: ref.watch(loadRecipeLocalDataSourceProvider),
    rangeSessionDataSource: ref.watch(rangeSessionLocalDataSourceProvider),
    targetDataSource: ref.watch(targetLocalDataSourceProvider),
    shotVelocityDataSource: ref.watch(shotVelocityLocalDataSourceProvider),
  );
});

/// Provider for DataImportService
final dataImportServiceProvider = Provider<DataImportService>((ref) {
  return DataImportService(
    database: ref.watch(databaseProvider),
    firearmDataSource: ref.watch(firearmLocalDataSourceProvider),
    loadRecipeDataSource: ref.watch(loadRecipeLocalDataSourceProvider),
    rangeSessionDataSource: ref.watch(rangeSessionLocalDataSourceProvider),
    targetDataSource: ref.watch(targetLocalDataSourceProvider),
    shotVelocityDataSource: ref.watch(shotVelocityLocalDataSourceProvider),
  );
});

/// Provider for export preview (metadata about what will be exported)
final exportPreviewProvider = FutureProvider<ExportMetadata>((ref) async {
  final exportService = ref.watch(dataExportServiceProvider);
  return await exportService.getExportPreview();
});

/// Provider for app version
final appVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return 'v${packageInfo.version} (${packageInfo.buildNumber})';
});
