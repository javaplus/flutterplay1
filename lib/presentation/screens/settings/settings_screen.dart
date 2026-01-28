import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/export_import_provider.dart';

/// Settings screen with export/import functionality
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Data Management Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Export Data
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Data'),
            subtitle: const Text('Create a backup of all your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExportDialog(context),
          ),

          const Divider(indent: 72),

          // Import Data
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore data from a backup file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showImportDialog(context),
          ),

          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Consumer(
              builder: (context, ref, child) {
                final versionAsync = ref.watch(appVersionProvider);
                return versionAsync.when(
                  data: (version) => Text(version),
                  loading: () => const Text('Loading...'),
                  error: (e, s) => const Text('Unknown'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    // First, get a preview of what will be exported
    final previewAsync = ref.read(exportPreviewProvider.future);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<ExportMetadata>(
        future: previewAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Preparing export preview...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to prepare export: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          final metadata = snapshot.data!;
          return AlertDialog(
            title: const Text('Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following data will be exported:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildExportPreviewItem(
                  Icons.gps_fixed,
                  'Firearms',
                  metadata.totalFirearms,
                ),
                _buildExportPreviewItem(
                  Icons.science,
                  'Load Recipes',
                  metadata.totalLoadRecipes,
                ),
                _buildExportPreviewItem(
                  Icons.event,
                  'Range Sessions',
                  metadata.totalRangeSessions,
                ),
                _buildExportPreviewItem(
                  Icons.track_changes,
                  'Targets',
                  metadata.totalTargets,
                ),
                _buildExportPreviewItem(
                  Icons.speed,
                  'Shot Velocities',
                  metadata.totalShotVelocities,
                ),
                _buildExportPreviewItem(
                  Icons.image,
                  'Images',
                  metadata.totalImages,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A ZIP file will be created and you can share it to your preferred location.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startExport(context);
                },
                child: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExportPreviewItem(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _startExport(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ExportProgressDialog(),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    // First, pick a file
    final importService = ref.read(dataImportServiceProvider);
    final filePath = await importService.pickBackupFile();

    if (filePath == null) return;
    if (!context.mounted) return;

    // Validate the file
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportValidationDialog(filePath: filePath),
    );
  }
}

/// Dialog showing export progress
class _ExportProgressDialog extends ConsumerStatefulWidget {
  const _ExportProgressDialog();

  @override
  ConsumerState<_ExportProgressDialog> createState() =>
      _ExportProgressDialogState();
}

class _ExportProgressDialogState extends ConsumerState<_ExportProgressDialog> {
  ExportImportProgress? _currentProgress;
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    final exportService = ref.read(dataExportServiceProvider);

    try {
      await for (final progress in exportService.exportData()) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
            if (progress.current >= progress.total) {
              _isComplete = true;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Export Failed'),
          ],
        ),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    if (_isComplete) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Complete'),
          ],
        ),
        content: const Text(
          'Your data has been exported successfully. Use the share sheet to save the backup to your preferred location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Exporting Data...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _currentProgress != null
                ? _currentProgress!.percentage / 100
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _currentProgress?.stage ?? 'Preparing...',
            style: const TextStyle(fontSize: 14),
          ),
          if (_currentProgress != null)
            Text(
              '${_currentProgress!.percentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

/// Dialog for validating import file and selecting import mode
class _ImportValidationDialog extends ConsumerStatefulWidget {
  final String filePath;

  const _ImportValidationDialog({required this.filePath});

  @override
  ConsumerState<_ImportValidationDialog> createState() =>
      _ImportValidationDialogState();
}

class _ImportValidationDialogState
    extends ConsumerState<_ImportValidationDialog> {
  bool _isValidating = true;
  ImportValidationResult? _validationResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _validateFile();
  }

  Future<void> _validateFile() async {
    final importService = ref.read(dataImportServiceProvider);

    try {
      final result = await importService.validateImportFile(widget.filePath);
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Validating backup file...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Invalid Backup'),
          ],
        ),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final result = _validationResult!;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return AlertDialog(
      title: const Text('Import Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.needsMigration)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This backup is from an older version. Data will be migrated automatically.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Backup Details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Created', dateFormat.format(result.exportedAt)),
          _buildDetailRow('App Version', result.appVersion),
          _buildDetailRow('Firearms', result.metadata.totalFirearms.toString()),
          _buildDetailRow(
            'Load Recipes',
            result.metadata.totalLoadRecipes.toString(),
          ),
          _buildDetailRow(
            'Range Sessions',
            result.metadata.totalRangeSessions.toString(),
          ),
          _buildDetailRow('Targets', result.metadata.totalTargets.toString()),
          _buildDetailRow('Images', result.imageCount.toString()),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Import Mode:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how to handle existing data:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => _confirmReplace(context),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Replace All'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _startImport(context, ImportMode.merge);
          },
          child: const Text('Merge'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmReplace(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Replace All Data?'),
          ],
        ),
        content: const Text(
          'This will DELETE all existing data in the app and replace it with the backup data. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close validation dialog
              _startImport(context, ImportMode.replace);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Replace All'),
          ),
        ],
      ),
    );
  }

  void _startImport(BuildContext context, ImportMode mode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ImportProgressDialog(filePath: widget.filePath, mode: mode),
    );
  }
}

/// Dialog showing import progress
class _ImportProgressDialog extends ConsumerStatefulWidget {
  final String filePath;
  final ImportMode mode;

  const _ImportProgressDialog({required this.filePath, required this.mode});

  @override
  ConsumerState<_ImportProgressDialog> createState() =>
      _ImportProgressDialogState();
}

class _ImportProgressDialogState extends ConsumerState<_ImportProgressDialog> {
  ExportImportProgress? _currentProgress;
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
    _startImport();
  }

  Future<void> _startImport() async {
    final importService = ref.read(dataImportServiceProvider);

    await for (final update in importService.importData(
      widget.filePath,
      widget.mode,
    )) {
      if (mounted) {
        setState(() {
          _currentProgress = update.progress;
          if (update.result != null) {
            _result = update.result;
          }
        });
      }
    }

    // Refresh all providers after import
    if (_result?.success == true) {
      ref.invalidate(exportPreviewProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      if (_result!.success) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Import Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Import Summary:'),
              const SizedBox(height: 8),
              _buildResultRow(
                'Firearms',
                _result!.firearmsImported,
                _result!.firearmsSkipped,
              ),
              _buildResultRow(
                'Load Recipes',
                _result!.loadRecipesImported,
                _result!.loadRecipesSkipped,
              ),
              _buildResultRow(
                'Range Sessions',
                _result!.rangeSessionsImported,
                _result!.rangeSessionsSkipped,
              ),
              _buildResultRow(
                'Targets',
                _result!.targetsImported,
                _result!.targetsSkipped,
              ),
              _buildResultRow(
                'Shot Velocities',
                _result!.shotVelocitiesImported,
                _result!.shotVelocitiesSkipped,
              ),
              _buildResultRow('Images', _result!.imagesImported, 0),
              const SizedBox(height: 16),
              Text(
                'Total imported: ${_result!.totalImported}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_result!.totalSkipped > 0)
                Text(
                  'Skipped (already exists): ${_result!.totalSkipped}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate back to home and refresh
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        );
      } else {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Import Failed'),
            ],
          ),
          content: Text(_result!.errorMessage ?? 'Unknown error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      }
    }

    return AlertDialog(
      title: const Text('Importing Data...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _currentProgress != null
                ? _currentProgress!.percentage / 100
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _currentProgress?.stage ?? 'Preparing...',
            style: const TextStyle(fontSize: 14),
          ),
          if (_currentProgress != null)
            Text(
              '${_currentProgress!.percentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, int imported, int skipped) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '+$imported',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (skipped > 0) ...[
            const SizedBox(width: 8),
            Text(
              '($skipped skipped)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
