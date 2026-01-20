import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Helper class for processing chronograph OCR
class ChronographOCRProcessor {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final StreamController<double> _velocityStreamController =
      StreamController<double>.broadcast();

  double? _lastVelocity;
  DateTime? _lastDetectionTime;
  final List<double> _recentDetections = [];
  final int _confirmationFrames = 3; // Require 3/5 frames to match
  final int _maxRecentFrames = 5;
  final Duration _debounceDelay = const Duration(milliseconds: 200);

  ui.Rect? _roiRect; // Region of Interest
  bool _isProcessing = false;
  int _frameCount = 0;

  Stream<double> get velocityStream => _velocityStreamController.stream;
  ui.Rect? get roiRect => _roiRect;

  /// Set the Region of Interest for OCR
  void setROI(ui.Rect rect) {
    _roiRect = rect;
    if (kDebugMode) {
      print(
        'ROI set: ${rect.left}, ${rect.top}, ${rect.width}, ${rect.height}',
      );
    }
  }

  /// Process a camera image and extract velocity
  Future<void> processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    _frameCount++;
    if (kDebugMode && _frameCount % 30 == 0) {
      print('📸 Processing frame $_frameCount...');
    }

    try {
      // Check debounce delay
      if (_lastDetectionTime != null) {
        final timeSinceLastDetection = DateTime.now().difference(
          _lastDetectionTime!,
        );
        if (timeSinceLastDetection < _debounceDelay) {
          _isProcessing = false;
          return;
        }
      }

      // Only process every 3rd frame to reduce load
      if (_frameCount % 3 != 0) {
        _isProcessing = false;
        return;
      }

      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        if (kDebugMode && _frameCount <= 3) {
          print('⚠️ Failed to convert camera image to InputImage');
        }
        _isProcessing = false;
        return;
      }

      // Run OCR
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Debug output
      if (kDebugMode && recognizedText.text.isNotEmpty) {
        print('OCR detected text: "${recognizedText.text}"');
      }

      // Extract velocity from text
      final velocity = _extractVelocity(recognizedText.text);

      if (velocity != null) {
        if (kDebugMode) {
          print('✓ Velocity extracted: $velocity fps');
        }
        _addDetection(velocity);
      } else if (kDebugMode && recognizedText.text.isNotEmpty) {
        print('✗ No valid velocity found in text: "${recognizedText.text}"');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ OCR processing error: $e');
        print('Stack trace: $stackTrace');
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Add a detection and check if it should be confirmed
  void _addDetection(double velocity) {
    // Add to recent detections
    _recentDetections.add(velocity);
    if (_recentDetections.length > _maxRecentFrames) {
      _recentDetections.removeAt(0);
    }

    if (kDebugMode) {
      print(
        'Recent detections buffer: $_recentDetections (${_recentDetections.length}/$_maxRecentFrames)',
      );
    }

    // Check if we have enough confirmations
    if (_recentDetections.length >= _maxRecentFrames) {
      final confirmedVelocity = _getConfirmedVelocity();
      if (confirmedVelocity != null && confirmedVelocity != _lastVelocity) {
        if (kDebugMode) {
          print('✓ Velocity CONFIRMED: $confirmedVelocity fps');
        }
        _lastVelocity = confirmedVelocity;
        _lastDetectionTime = DateTime.now();
        _velocityStreamController.add(confirmedVelocity);
        _recentDetections.clear(); // Clear after successful detection
      }
    }
  }

  /// Get confirmed velocity if at least N frames agree
  double? _getConfirmedVelocity() {
    if (_recentDetections.length < _confirmationFrames) return null;

    // Group velocities within 10 fps tolerance
    final Map<double, int> velocityGroups = {};
    for (final velocity in _recentDetections) {
      bool foundGroup = false;
      for (final key in velocityGroups.keys) {
        if ((velocity - key).abs() <= 10) {
          velocityGroups[key] = velocityGroups[key]! + 1;
          foundGroup = true;
          break;
        }
      }
      if (!foundGroup) {
        velocityGroups[velocity] = 1;
      }
    }

    // Find the group with most occurrences
    double? bestVelocity;
    int maxCount = 0;
    velocityGroups.forEach((velocity, count) {
      if (count >= _confirmationFrames && count > maxCount) {
        bestVelocity = velocity;
        maxCount = count;
      }
    });

    return bestVelocity;
  }

  /// Extract velocity from OCR text
  double? _extractVelocity(String text) {
    // Remove whitespace but keep periods for decimals
    final cleaned = text.replaceAll(RegExp(r'\s+'), '');

    // Look for velocity patterns with optional decimal
    // Matches: 344.2, 2333.5, 1234, 567.8, etc.
    final velocityPattern = RegExp(r'(\d{3,4}(?:\.\d)?)');
    final matches = velocityPattern.allMatches(cleaned);

    for (final match in matches) {
      final velocityStr = match.group(1);
      if (velocityStr != null) {
        final velocity = double.tryParse(velocityStr);
        // Accept velocities in reasonable range (100-9999 fps)
        if (velocity != null && velocity >= 100 && velocity <= 9999) {
          return velocity;
        }
      }
    }

    return null;
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Get image rotation based on device orientation
      const InputImageRotation imageRotation = InputImageRotation.rotation0deg;

      // Get image format
      final InputImageFormat? inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw);

      if (inputImageFormat == null) {
        if (kDebugMode) {
          print('⚠️ Unsupported image format: ${image.format.raw}');
        }
        return null;
      }

      // For YUV420 format, we need to concatenate all plane bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Create metadata - use the first plane's bytesPerRow
      final inputImageMetadata = InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('⚠️ Image conversion error: $e');
        print('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Manually add a velocity (for manual entry button)
  void addManualVelocity(double velocity) {
    _lastVelocity = velocity;
    _lastDetectionTime = DateTime.now();
    _velocityStreamController.add(velocity);
    _recentDetections.clear();
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _velocityStreamController.close();
  }
}
