import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Screen for analyzing target photos by marking shot holes,
/// setting reference scale, and calculating group size
class TargetPhotoAnalysisScreen extends StatefulWidget {
  final String photoPath;
  final Function(TargetAnalysisResult) onAnalysisComplete;

  const TargetPhotoAnalysisScreen({
    super.key,
    required this.photoPath,
    required this.onAnalysisComplete,
  });

  @override
  State<TargetPhotoAnalysisScreen> createState() =>
      _TargetPhotoAnalysisScreenState();
}

class _TargetPhotoAnalysisScreenState extends State<TargetPhotoAnalysisScreen> {
  final List<Offset> _shotHoles = [];
  final List<Offset> _referencePoints = [];
  ui.Image? _image;
  bool _isLoadingImage = true;
  Size _imageSize = Size.zero;
  double _displayScale = 1.0;
  final TransformationController _transformationController =
      TransformationController();

  // UI state
  AnalysisMode _mode = AnalysisMode.markingShots;
  final _referenceDistanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadImage();
    // Listen to text field changes to update button state
    _referenceDistanceController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _referenceDistanceController.dispose();
    _transformationController.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      final file = File(widget.photoPath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _image = frame.image;
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _isLoadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Target'),
        actions: [
          if (_mode == AnalysisMode.markingShots && _shotHoles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Remove last shot',
              onPressed: () {
                setState(() {
                  _shotHoles.removeLast();
                });
              },
            ),
          if (_mode == AnalysisMode.settingScale && _referencePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Remove last point',
              onPressed: () {
                setState(() {
                  _referencePoints.removeLast();
                });
              },
            ),
        ],
      ),
      body: _isLoadingImage
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Instructions card
                Card(
                  margin: const EdgeInsets.all(16),
                  color: _getModeColor(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getModeIcon(), color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getModeTitle(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getModeInstructions(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (_mode == AnalysisMode.markingShots) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Shots marked: ${_shotHoles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (_mode == AnalysisMode.settingScale) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Points marked: ${_referencePoints.length}/2',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Image with overlay
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate scale to fit image in available space
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;
                      final imageAspect = _imageSize.width / _imageSize.height;
                      final availableAspect = availableWidth / availableHeight;

                      double displayWidth, displayHeight;
                      if (imageAspect > availableAspect) {
                        // Image is wider - fit to width
                        displayWidth = availableWidth;
                        displayHeight = availableWidth / imageAspect;
                      } else {
                        // Image is taller - fit to height
                        displayHeight = availableHeight;
                        displayWidth = availableHeight * imageAspect;
                      }

                      _displayScale = displayWidth / _imageSize.width;

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Center(
                          child: GestureDetector(
                            onTapDown: (details) => _handleTap(
                              details,
                              displayWidth,
                              displayHeight,
                            ),
                            child: CustomPaint(
                              painter: TargetAnalysisPainter(
                                image: _image,
                                shotHoles: _shotHoles,
                                referencePoints: _referencePoints,
                                mode: _mode,
                                imageSize: _imageSize,
                                displayScale: _displayScale,
                              ),
                              child: SizedBox(
                                width: displayWidth,
                                height: displayHeight,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(child: _buildActionButtons()),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    switch (_mode) {
      case AnalysisMode.markingShots:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_shotHoles.length >= 2)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _mode = AnalysisMode.settingScale;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Next: Set Reference Scale'),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Mark at least ${2 - _shotHoles.length} more shot(s)',
                    ),
                  ),
                ),
              ),
          ],
        );

      case AnalysisMode.settingScale:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_referencePoints.length == 2) ...[
              TextField(
                controller: _referenceDistanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Reference Distance (inches)',
                  hintText: 'e.g., 1.0 for 1 inch',
                  border: OutlineInputBorder(),
                  helperText:
                      'Enter the actual distance between the two points',
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _referencePoints.clear();
                        _mode = AnalysisMode.markingShots;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Back'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _referencePoints.length == 2 &&
                            _referenceDistanceController.text.isNotEmpty
                        ? _calculateResults
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Calculate Group'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  void _handleTap(
    TapDownDetails details,
    double displayWidth,
    double displayHeight,
  ) {
    // Get tap position relative to the CustomPaint widget
    final Offset localPosition = details.localPosition;

    // The tap position is now in scaled/display coordinates
    // We need to convert it to original image coordinates
    final imageX = localPosition.dx / _displayScale;
    final imageY = localPosition.dy / _displayScale;
    final imagePosition = Offset(imageX, imageY);

    // Validate the tap is within image bounds
    if (imageX >= 0 &&
        imageX <= _imageSize.width &&
        imageY >= 0 &&
        imageY <= _imageSize.height) {
      setState(() {
        if (_mode == AnalysisMode.markingShots) {
          _shotHoles.add(imagePosition);
        } else if (_mode == AnalysisMode.settingScale) {
          if (_referencePoints.length < 2) {
            _referencePoints.add(imagePosition);
          }
        }
      });
    }
  }

  void _calculateResults() {
    if (_shotHoles.length < 2 ||
        _referencePoints.length != 2 ||
        _referenceDistanceController.text.isEmpty) {
      return;
    }

    final refDistance = double.tryParse(_referenceDistanceController.text);
    if (refDistance == null || refDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid reference distance'),
        ),
      );
      return;
    }

    // Calculate pixels per inch from reference points
    final refPixelDistance = _calculateDistance(
      _referencePoints[0],
      _referencePoints[1],
    );
    final pixelsPerInch = refPixelDistance / refDistance;

    // Calculate group center (centroid of all shot holes)
    final centerX =
        _shotHoles.map((p) => p.dx).reduce((a, b) => a + b) / _shotHoles.length;
    final centerY =
        _shotHoles.map((p) => p.dy).reduce((a, b) => a + b) / _shotHoles.length;
    final groupCenter = Offset(centerX, centerY);

    // Find the two shots that are farthest apart (extreme spread)
    double maxDistancePixels = 0;
    for (int i = 0; i < _shotHoles.length; i++) {
      for (int j = i + 1; j < _shotHoles.length; j++) {
        final distance = _calculateDistance(_shotHoles[i], _shotHoles[j]);
        if (distance > maxDistancePixels) {
          maxDistancePixels = distance;
        }
      }
    }

    // Convert to inches
    final groupSizeInches = maxDistancePixels / pixelsPerInch;

    final result = TargetAnalysisResult(
      numberOfShots: _shotHoles.length,
      groupSizeInches: groupSizeInches,
      groupCenter: groupCenter,
      shotHolePositions: List.from(_shotHoles),
      referenceDistanceInches: refDistance,
      pixelsPerInch: pixelsPerInch,
    );

    widget.onAnalysisComplete(result);
    Navigator.pop(context, result);
  }

  double _calculateDistance(Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Color _getModeColor() {
    switch (_mode) {
      case AnalysisMode.markingShots:
        return Colors.blue;
      case AnalysisMode.settingScale:
        return Colors.orange;
    }
  }

  IconData _getModeIcon() {
    switch (_mode) {
      case AnalysisMode.markingShots:
        return Icons.my_location;
      case AnalysisMode.settingScale:
        return Icons.straighten;
    }
  }

  String _getModeTitle() {
    switch (_mode) {
      case AnalysisMode.markingShots:
        return 'Step 1: Mark Shot Holes';
      case AnalysisMode.settingScale:
        return 'Step 2: Set Reference Scale';
    }
  }

  String _getModeInstructions() {
    switch (_mode) {
      case AnalysisMode.markingShots:
        return 'Tap on each shot hole in your target. Mark at least 2 shots.';
      case AnalysisMode.settingScale:
        return 'Tap two points on a known distance (e.g., opposite edges of a 1-inch grid square, or a ruler).';
    }
  }
}

enum AnalysisMode { markingShots, settingScale }

/// Custom painter to draw the target image with shot holes and reference points
class TargetAnalysisPainter extends CustomPainter {
  final ui.Image? image;
  final List<Offset> shotHoles;
  final List<Offset> referencePoints;
  final AnalysisMode mode;
  final Size imageSize;
  final double displayScale;

  TargetAnalysisPainter({
    required this.image,
    required this.shotHoles,
    required this.referencePoints,
    required this.mode,
    required this.imageSize,
    required this.displayScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image scaled to fit the display size
    if (image != null) {
      canvas.save();
      canvas.scale(displayScale, displayScale);
      canvas.drawImage(image!, Offset.zero, Paint());
      canvas.restore();
    }

    // Draw shot holes (scale coordinates to display size)
    final shotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final shotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final hole in shotHoles) {
      final displayHole = Offset(
        hole.dx * displayScale,
        hole.dy * displayScale,
      );
      canvas.drawCircle(displayHole, 8, shotPaint);
      canvas.drawCircle(displayHole, 8, shotBorderPaint);
    }

    // Draw shot hole numbers
    for (int i = 0; i < shotHoles.length; i++) {
      final displayHole = Offset(
        shotHoles[i].dx * displayScale,
        shotHoles[i].dy * displayScale,
      );
      final textSpan = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        displayHole - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw reference points (scale coordinates to display size)
    final refPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    final refBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in referencePoints) {
      final displayPoint = Offset(
        point.dx * displayScale,
        point.dy * displayScale,
      );
      canvas.drawCircle(displayPoint, 10, refPaint);
      canvas.drawCircle(displayPoint, 10, refBorderPaint);
    }

    // Draw line between reference points
    if (referencePoints.length == 2) {
      final linePaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final displayPoint0 = Offset(
        referencePoints[0].dx * displayScale,
        referencePoints[0].dy * displayScale,
      );
      final displayPoint1 = Offset(
        referencePoints[1].dx * displayScale,
        referencePoints[1].dy * displayScale,
      );
      canvas.drawLine(displayPoint0, displayPoint1, linePaint);
    }

    // Draw group center and size if we have enough data
    if (shotHoles.length >= 2) {
      final centerX =
          shotHoles.map((p) => p.dx).reduce((a, b) => a + b) / shotHoles.length;
      final centerY =
          shotHoles.map((p) => p.dy).reduce((a, b) => a + b) / shotHoles.length;
      final groupCenter = Offset(centerX, centerY);
      final displayCenter = Offset(
        groupCenter.dx * displayScale,
        groupCenter.dy * displayScale,
      );

      // Draw center point
      final centerPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      final centerBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(displayCenter, 6, centerPaint);
      canvas.drawCircle(displayCenter, 6, centerBorderPaint);

      // Draw lines from center to each shot
      final linePaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..strokeWidth = 1;

      for (final hole in shotHoles) {
        final displayHole = Offset(
          hole.dx * displayScale,
          hole.dy * displayScale,
        );
        canvas.drawLine(displayCenter, displayHole, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(TargetAnalysisPainter oldDelegate) {
    return shotHoles != oldDelegate.shotHoles ||
        referencePoints != oldDelegate.referencePoints ||
        mode != oldDelegate.mode ||
        displayScale != oldDelegate.displayScale;
  }
}

/// Result of target analysis
class TargetAnalysisResult {
  final int numberOfShots;
  final double groupSizeInches;
  final Offset groupCenter;
  final List<Offset> shotHolePositions;
  final double referenceDistanceInches;
  final double pixelsPerInch;

  TargetAnalysisResult({
    required this.numberOfShots,
    required this.groupSizeInches,
    required this.groupCenter,
    required this.shotHolePositions,
    required this.referenceDistanceInches,
    required this.pixelsPerInch,
  });
}
