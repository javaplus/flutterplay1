import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/shot_velocity.dart';
import '../../providers/shot_velocity_provider.dart';
import '../../providers/range_session_provider.dart' as range_session;
import 'chronograph_ocr_processor.dart';

/// Screen for capturing velocities from a chronograph using camera OCR
class ChronographCameraScreen extends ConsumerStatefulWidget {
  final String targetId;

  const ChronographCameraScreen({super.key, required this.targetId});

  @override
  ConsumerState<ChronographCameraScreen> createState() =>
      _ChronographCameraScreenState();
}

class _ChronographCameraScreenState
    extends ConsumerState<ChronographCameraScreen> {
  CameraController? _cameraController;
  ChronographOCRProcessor? _ocrProcessor;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCalibrating = false;
  ui.Rect? _roiRect;
  final List<double> _capturedVelocities = [];
  StreamSubscription<double>? _velocitySubscription;

  // For ROI calibration
  Offset? _roiStart;
  Offset? _roiEnd;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use back camera (typically index 0)
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium, // Use medium for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Changed from yuv420
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      if (kDebugMode) {
        print('✅ Camera initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Camera initialization error: $e');
        print('Stack trace: $stackTrace');
      }
      _showError('Error initializing camera: $e');
    }
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _roiStart = null;
      _roiEnd = null;
      _roiRect = null;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isCalibrating) return;
    setState(() {
      _roiStart = details.localPosition;
      _roiEnd = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isCalibrating) return;
    setState(() {
      _roiEnd = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isCalibrating || _roiStart == null || _roiEnd == null) return;

    final rect = ui.Rect.fromPoints(_roiStart!, _roiEnd!);
    setState(() {
      _roiRect = rect;
      _isCalibrating = false;
    });

    _ocrProcessor?.setROI(rect);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ROI calibrated! Tap "Start Recording" to begin.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startRecording() {
    if (_roiRect == null) {
      _showError('Please calibrate ROI first');
      return;
    }

    if (kDebugMode) {
      print('🎬 Starting velocity recording...');
      print('Camera initialized: ${_cameraController?.value.isInitialized}');
      print('ROI: $_roiRect');
    }

    setState(() {
      _isRecording = true;
      _capturedVelocities.clear();
    });

    _ocrProcessor = ChronographOCRProcessor();
    _ocrProcessor!.setROI(_roiRect!);

    // Listen to velocity stream
    _velocitySubscription = _ocrProcessor!.velocityStream.listen(
      (velocity) {
        if (kDebugMode) {
          print('📥 Received velocity from stream: $velocity fps');
        }
        setState(() {
          _capturedVelocities.add(velocity);
        });

        _saveVelocityToDatabase(velocity);

        // Haptic feedback
        if (mounted) {
          HapticFeedback.mediumImpact();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Velocity stream error: $error');
        }
        _showError('Stream error: $error');
      },
    );

    // Start image stream processing
    try {
      _cameraController
          ?.startImageStream((image) async {
            try {
              await _ocrProcessor?.processImage(image);
            } catch (e) {
              if (kDebugMode) {
                print('❌ Error processing image: $e');
              }
            }
          })
          .then((_) {
            if (kDebugMode) {
              print('✅ Image stream started successfully');
            }
          })
          .catchError((error) {
            if (kDebugMode) {
              print('❌ Failed to start image stream: $error');
            }
            _showError('Failed to start recording: $error');
            _stopRecording();
          });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception starting image stream: $e');
      }
      _showError('Failed to start recording: $e');
      _stopRecording();
    }
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
    });

    await _cameraController?.stopImageStream();
    await _velocitySubscription?.cancel();
    _ocrProcessor?.dispose();
    _ocrProcessor = null;
  }

  void _addManualVelocity() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Velocity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Velocity (fps)',
              hintText: '2850',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final velocity = double.tryParse(controller.text);
                if (velocity != null) {
                  setState(() {
                    _capturedVelocities.add(velocity);
                  });
                  _saveVelocityToDatabase(velocity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid velocity')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveVelocityToDatabase(double velocity) async {
    final shotVelocity = ShotVelocity(
      id: const Uuid().v4(),
      targetId: widget.targetId,
      velocity: velocity,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(shotVelocityNotifierProvider.notifier);
    await notifier.addShotVelocity(shotVelocity);
  }

  void _deleteVelocity(int index) {
    setState(() {
      _capturedVelocities.removeAt(index);
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _saveAndReturn() async {
    if (_capturedVelocities.isEmpty) {
      _showError('No velocities captured');
      return;
    }

    // Fetch ALL velocities from database (including previously recorded ones)
    final shotVelocityRepository = ref.read(shotVelocityRepositoryProvider);
    final allVelocities = await shotVelocityRepository
        .getShotVelocitiesByTargetId(widget.targetId);
    final allVelocityValues = allVelocities.map((v) => v.velocity).toList();

    if (allVelocityValues.isEmpty) {
      _showError('No velocities found in database');
      return;
    }

    // Calculate statistics from ALL velocities
    final avgVelocity =
        allVelocityValues.reduce((a, b) => a + b) / allVelocityValues.length;
    final sortedVelocities = List<double>.from(allVelocityValues)..sort();
    final extremeSpread = sortedVelocities.last - sortedVelocities.first;

    double? standardDeviation;
    if (allVelocityValues.length > 1) {
      final variance =
          allVelocityValues
              .map((v) => math.pow(v - avgVelocity, 2))
              .reduce((a, b) => a + b) /
          allVelocityValues.length;
      standardDeviation = math.sqrt(variance);
    }

    // Update the target with velocity statistics
    final targetNotifier = ref.read(
      range_session.targetNotifierProvider.notifier,
    );
    await targetNotifier.updateTargetVelocityStats(
      widget.targetId,
      avgVelocity,
      standardDeviation,
      extremeSpread,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${_capturedVelocities.length} new velocities. Total: ${allVelocityValues.length}, Avg: ${avgVelocity.toStringAsFixed(1)} fps',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _velocitySubscription?.cancel();
    _ocrProcessor?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronograph Reader'),
        actions: [
          if (_capturedVelocities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveAndReturn,
              tooltip: 'Save & Return',
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Camera Preview with ROI overlay
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      // Camera preview
                      Center(
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),

                      // ROI overlay
                      if (_roiRect != null)
                        Positioned.fill(
                          child: CustomPaint(painter: ROIPainter(_roiRect!)),
                        ),

                      // Calibration overlay
                      if (_isCalibrating)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: CalibrationPainter(_roiStart, _roiEnd),
                            ),
                          ),
                        ),

                      // Instructions
                      if (_isCalibrating)
                        const Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Draw a box around the velocity display',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Recording indicator
                      if (_isRecording)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'RECORDING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Main action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_isRecording && !_isCalibrating)
                            ElevatedButton.icon(
                              onPressed: _startCalibration,
                              icon: const Icon(Icons.crop_free),
                              label: const Text('Calibrate ROI'),
                            ),
                          if (!_isRecording &&
                              !_isCalibrating &&
                              _roiRect != null)
                            ElevatedButton.icon(
                              onPressed: _startRecording,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          if (_isRecording)
                            ElevatedButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          IconButton(
                            onPressed: _addManualVelocity,
                            icon: const Icon(Icons.edit),
                            tooltip: 'Manual Entry',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Captured velocities list
                Expanded(
                  child: _capturedVelocities.isEmpty
                      ? const Center(child: Text('No velocities captured yet'))
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Captured: ${_capturedVelocities.length} shots',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (_capturedVelocities.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildStatsCard(),
                              ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _capturedVelocities.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text(
                                      '${_capturedVelocities[index].toStringAsFixed(0)} fps',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteVelocity(index),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard() {
    if (_capturedVelocities.isEmpty) return const SizedBox.shrink();

    final avg =
        _capturedVelocities.reduce((a, b) => a + b) /
        _capturedVelocities.length;

    final sortedVelocities = List<double>.from(_capturedVelocities)..sort();
    final es = sortedVelocities.last - sortedVelocities.first;

    double sd = 0;
    if (_capturedVelocities.length > 1) {
      final variance =
          _capturedVelocities
              .map((v) => (v - avg) * (v - avg))
              .reduce((a, b) => a + b) /
          _capturedVelocities.length;
      sd = math.sqrt(variance);
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Avg', '${avg.toStringAsFixed(1)} fps'),
            _buildStatColumn('SD', '${sd.toStringAsFixed(2)} fps'),
            _buildStatColumn('ES', '${es.toStringAsFixed(1)} fps'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Custom painter for ROI rectangle
class ROIPainter extends CustomPainter {
  final ui.Rect rect;

  ROIPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(rect, paint);

    // Draw corner markers
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(0, cornerSize),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerSize),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(0, -cornerSize),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(0, -cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for calibration overlay
class CalibrationPainter extends CustomPainter {
  final Offset? start;
  final Offset? end;

  CalibrationPainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final rect = Rect.fromPoints(start!, end!);

    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Clear the ROI area
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(rect, clearPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
