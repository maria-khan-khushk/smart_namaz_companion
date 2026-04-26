import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/language_provider.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  double _qiblaBearing = 0.0; // True bearing from North to Kaaba
  double _deviceHeading = 0.0; // Device's current compass heading (from North)
  bool _hasLocation = false;
  bool _isLoading = true;
  String _errorMessage = '';

  // Smoothing buffer for compass stability
  final List<double> _headingBuffer = [];
  static const int _bufferSize = 5;

  // Sensor streams
  final List<dynamic> _streamSubscriptions = [];

  // Raw sensor values for tilt-compensated heading
  double _ax = 0, _ay = 0, _az = 0; // Accelerometer
  double _mx = 0, _my = 0, _mz = 0; // Magnetometer

  // Animation for smooth arrow rotation
  late AnimationController _animController;
  late Animation<double> _animation;
  double _lastArrowAngle = 0;

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _checkPermissionsAndGetLocation();
    _startSensors();
  }

  void _startSensors() {
    // Accelerometer for tilt compensation
    _streamSubscriptions.add(
      accelerometerEventStream().listen((AccelerometerEvent e) {
        _ax = e.x; _ay = e.y; _az = e.z;
        _updateHeading();
      }),
    );

    // Magnetometer
    _streamSubscriptions.add(
      magnetometerEventStream().listen((MagnetometerEvent e) {
        _mx = e.x; _my = e.y; _mz = e.z;
        _updateHeading();
      }),
    );
  }

  /// Tilt-compensated compass heading using accelerometer + magnetometer
  void _updateHeading() {
    // Normalize accelerometer
    double norm = sqrt(_ax * _ax + _ay * _ay + _az * _az);
    if (norm == 0) return;
    double ax = _ax / norm, ay = _ay / norm, az = _az / norm;

    // Compute rotation matrix elements for tilt compensation
    double pitch = asin(-ax);
    double roll = atan2(ay, az);

    // Tilt-compensated magnetic field components
    double mxComp = _mx * cos(pitch) + _mz * sin(pitch);
    double myComp = _mx * sin(roll) * sin(pitch) +
        _my * cos(roll) -
        _mz * sin(roll) * cos(pitch);

    double heading = atan2(-myComp, mxComp) * 180 / pi;
    heading = (heading + 360) % 360;

    // Smooth heading using circular mean buffer
    _headingBuffer.add(heading);
    if (_headingBuffer.length > _bufferSize) _headingBuffer.removeAt(0);
    double smoothed = _circularMean(_headingBuffer);

    if (mounted) {
      setState(() {
        _deviceHeading = smoothed;
      });
      _animateArrow();
    }
  }

  /// Circular mean to average angles correctly (avoids 359°/1° averaging to 180°)
  double _circularMean(List<double> angles) {
    double sinSum = 0, cosSum = 0;
    for (final a in angles) {
      sinSum += sin(a * pi / 180);
      cosSum += cos(a * pi / 180);
    }
    double mean = atan2(sinSum / angles.length, cosSum / angles.length) * 180 / pi;
    return (mean + 360) % 360;
  }

  void _animateArrow() {
    // Arrow angle = Qibla bearing − device heading (how much to rotate arrow)
    double targetAngle = (_qiblaBearing - _deviceHeading) * pi / 180;

    // Shortest rotation path to avoid spinning 350° the wrong way
    double diff = targetAngle - _lastArrowAngle;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;

    double newTarget = _lastArrowAngle + diff;
    _animation = Tween<double>(begin: _lastArrowAngle, end: newTarget).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0);
    _lastArrowAngle = newTarget;
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final result = await _requestPermission();
      if (!result) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission is required to find Qibla direction.';
        });
        return;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enable location services to find Qibla direction.';
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _calculateQiblaBearing(pos.latitude, pos.longitude);
      setState(() {
        _hasLocation = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) openAppSettings();
    return false;
  }

  void _calculateQiblaBearing(double userLat, double userLon) {
    double lat1 = userLat * pi / 180;
    double lon1 = userLon * pi / 180;
    double lat2 = kaabaLat * pi / 180;
    double lon2 = kaabaLon * pi / 180;
    double dLon = lon2 - lon1;
    double x = sin(dLon) * cos(lat2);
    double y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(x, y) * 180 / pi;
    setState(() {
      _qiblaBearing = (bearing + 360) % 360;
    });
  }

  @override
  void dispose() {
    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'قبلہ کی سمت' : 'Qibla Direction'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(isUrdu, primaryColor, cardColor, textSecondary),
    );
  }

  Widget _buildBody(
      bool isUrdu, Color primaryColor, Color cardColor, Color textSecondary) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              isUrdu
                  ? 'قبلہ کی سمت معلوم کی جا رہی ہے...'
                  : 'Determining Qibla direction...',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: TextStyle(color: textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissionsAndGetLocation,
                child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasLocation) {
      return Center(
          child: Text(
              isUrdu ? 'لوکیشن حاصل نہیں ہو سکی' : 'Unable to get location'));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Live compass card
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            color: cardColor,
            child: Container(
              width: 260,
              height: 260,
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: QiblaCompassPainter(
                      arrowAngleRad: _animation.value,
                      deviceHeadingDeg: _deviceHeading,
                      primaryColor: primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info cards row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoCard(
                isUrdu ? 'قبلہ' : 'Qibla',
                '${_qiblaBearing.toStringAsFixed(0)}°',
                primaryColor,
                cardColor,
                textSecondary,
              ),
              const SizedBox(width: 16),
              _infoCard(
                isUrdu ? 'فون کی سمت' : 'Heading',
                '${_deviceHeading.toStringAsFixed(0)}°',
                Colors.teal,
                cardColor,
                textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isUrdu
                  ? 'سبز تیر کو سامنے کریں — جب تیر اوپر کی طرف ہو تو آپ قبلہ رُخ ہیں۔'
                  : 'Rotate your phone until the arrow points straight up — you are then facing the Qibla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, Color valueColor,
      Color cardColor, Color textSecondary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }
}

/// Draws a compass rose with a Qibla arrow that rotates in real-time.
/// [arrowAngleRad] = 0 means arrow points UP (phone faces Qibla).
class QiblaCompassPainter extends CustomPainter {
  final double arrowAngleRad;
  final double deviceHeadingDeg;
  final Color primaryColor;

  QiblaCompassPainter({
    required this.arrowAngleRad,
    required this.deviceHeadingDeg,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // ── Background circle ──────────────────────────────────────────────────
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.withOpacity(0.08)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── Compass tick marks ─────────────────────────────────────────────────
    final tickPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 1;
    for (int i = 0; i < 36; i++) {
      double angle = i * 10 * pi / 180;
      bool isMajor = i % 9 == 0;
      double inner = isMajor ? radius - 14 : radius - 8;
      canvas.drawLine(
        Offset(center.dx + inner * sin(angle), center.dy - inner * cos(angle)),
        Offset(center.dx + radius * sin(angle),
            center.dy - radius * cos(angle)),
        tickPaint..strokeWidth = isMajor ? 2.0 : 1.0,
      );
    }

    // ── Cardinal labels (N/E/S/W) ─────────────────────────────────────────
    _drawCardinalLabel(canvas, center, radius, 'N', 0, Colors.red);
    _drawCardinalLabel(canvas, center, radius, 'E', pi / 2, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'S', pi, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'W', 3 * pi / 2, Colors.grey);

    // ── Qibla arrow ───────────────────────────────────────────────────────
    // arrowAngleRad = 0  → points up (12 o'clock) = phone faces Qibla
    final arrowLength = radius * 0.62;
    final tailLength = radius * 0.30;

    // Tip & tail positions
    final tip = Offset(
      center.dx + arrowLength * sin(arrowAngleRad),
      center.dy - arrowLength * cos(arrowAngleRad),
    );
    final tail = Offset(
      center.dx - tailLength * sin(arrowAngleRad),
      center.dy + tailLength * cos(arrowAngleRad),
    );

    // Shaft
    canvas.drawLine(
        tail,
        tip,
        Paint()
          ..color = primaryColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);

    // Arrowhead (filled triangle)
    final perpAngle = arrowAngleRad + pi / 2;
    const wingSpread = 12.0;
    const wingBack = 22.0;
    final leftWing = Offset(
      tip.dx - wingBack * sin(arrowAngleRad) + wingSpread * sin(perpAngle),
      tip.dy + wingBack * cos(arrowAngleRad) - wingSpread * cos(perpAngle),
    );
    final rightWing = Offset(
      tip.dx - wingBack * sin(arrowAngleRad) - wingSpread * sin(perpAngle),
      tip.dy + wingBack * cos(arrowAngleRad) + wingSpread * cos(perpAngle),
    );
    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = primaryColor);

    // Tail dot (opposite end)
    canvas.drawCircle(tail, 5, Paint()..color = primaryColor.withOpacity(0.5));

    // ── Kaaba icon at tip ─────────────────────────────────────────────────
    final tp = TextPainter(
      text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, Offset(tip.dx - tp.width / 2, tip.dy - tp.height / 2 - 14));

    // ── Centre dot ────────────────────────────────────────────────────────
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawCardinalLabel(Canvas canvas, Offset center, double radius,
      String label, double angle, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelRadius = radius - 22;
    tp.paint(
      canvas,
      Offset(
        center.dx + labelRadius * sin(angle) - tp.width / 2,
        center.dy - labelRadius * cos(angle) - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter old) =>
      old.arrowAngleRad != arrowAngleRad ||
      old.deviceHeadingDeg != deviceHeadingDeg;
}