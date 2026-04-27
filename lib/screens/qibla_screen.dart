import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mosque model
// ─────────────────────────────────────────────────────────────────────────────
class _Mosque {
  final String name;
  final double lat;
  final double lon;
  final double distanceKm;

  _Mosque({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceKm,
  });
}

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // ── Qibla compass state ───────────────────────────────────────────────────
  double _qiblaBearing = 0.0;
  double _deviceHeading = 0.0;
  bool _hasLocation = false;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;

  final List<double> _headingBuffer = [];
  static const int _bufferSize = 5;
  final List<dynamic> _streamSubscriptions = [];
  double _ax = 0, _ay = 0, _az = 0;
  double _mx = 0, _my = 0, _mz = 0;

  late AnimationController _animController;
  late Animation<double> _animation;
  double _lastArrowAngle = 0;

  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  // ── Mosque finder state ───────────────────────────────────────────────────
  List<_Mosque> _mosques = [];
  bool _isFindingMosques = false;
  String _mosqueError = '';
  bool _mosquesLoaded = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Init / dispose
  // ─────────────────────────────────────────────────────────────────────────

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

  @override
  void dispose() {
    for (final sub in _streamSubscriptions) sub.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sensors
  // ─────────────────────────────────────────────────────────────────────────

  void _startSensors() {
    _streamSubscriptions.add(
      accelerometerEventStream().listen((e) {
        _ax = e.x; _ay = e.y; _az = e.z;
        _updateHeading();
      }),
    );
    _streamSubscriptions.add(
      magnetometerEventStream().listen((e) {
        _mx = e.x; _my = e.y; _mz = e.z;
        _updateHeading();
      }),
    );
  }

  void _updateHeading() {
    double norm = sqrt(_ax * _ax + _ay * _ay + _az * _az);
    if (norm == 0) return;
    double ax = _ax / norm, ay = _ay / norm, az = _az / norm;
    double pitch = asin(-ax);
    double roll = atan2(ay, az);
    double mxComp = _mx * cos(pitch) + _mz * sin(pitch);
    double myComp = _mx * sin(roll) * sin(pitch) +
        _my * cos(roll) -
        _mz * sin(roll) * cos(pitch);
    double heading = atan2(-myComp, mxComp) * 180 / pi;
    heading = (heading + 360) % 360;
    _headingBuffer.add(heading);
    if (_headingBuffer.length > _bufferSize) _headingBuffer.removeAt(0);
    if (mounted) {
      setState(() => _deviceHeading = _circularMean(_headingBuffer));
      _animateArrow();
    }
  }

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
    double targetAngle = (_qiblaBearing - _deviceHeading) * pi / 180;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Location + Qibla
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _checkPermissionsAndGetLocation() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

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
      _currentPosition = pos;
      _calculateQiblaBearing(pos.latitude, pos.longitude);
      setState(() { _hasLocation = true; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Failed to get location: $e'; });
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
    setState(() => _qiblaBearing = (bearing + 360) % 360);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mosque finder — Overpass API (OpenStreetMap, no key needed)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _findNearbyMosques() async {
    if (_currentPosition == null) {
      setState(() => _mosqueError = 'Location not available. Please retry.');
      return;
    }

    setState(() {
      _isFindingMosques = true;
      _mosqueError = '';
      _mosques = [];
    });

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    const radiusMeters = 5000; // 5 km

    // Overpass QL query — finds all nodes/ways tagged amenity=place_of_worship + religion=muslim
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);
);
out center 30;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List<dynamic>;

      List<_Mosque> results = [];

      for (final el in elements) {
        // Ways return a 'center' node; nodes have direct lat/lon
        double? mLat, mLon;
        if (el['type'] == 'node') {
          mLat = (el['lat'] as num).toDouble();
          mLon = (el['lon'] as num).toDouble();
        } else if (el['type'] == 'way' && el['center'] != null) {
          mLat = (el['center']['lat'] as num).toDouble();
          mLon = (el['center']['lon'] as num).toDouble();
        }
        if (mLat == null || mLon == null) continue;

        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name = (tags['name'] as String?)?.trim() ??
            (tags['name:en'] as String?)?.trim() ??
            (tags['name:ur'] as String?)?.trim() ??
            'Mosque';

        final dist = _haversineKm(lat, lon, mLat, mLon);
        results.add(_Mosque(name: name, lat: mLat, lon: mLon, distanceKm: dist));
      }

      // Sort closest first
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      setState(() {
        _mosques = results;
        _mosquesLoaded = true;
        _isFindingMosques = false;
        if (results.isEmpty) _mosqueError = 'No mosques found within 5 km.';
      });
    } catch (e) {
      setState(() {
        _isFindingMosques = false;
        _mosqueError = 'Could not fetch mosques. Check your internet connection.';
      });
    }
  }

  /// Haversine formula — returns distance in km
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? 'قبلہ کی سمت' : 'Qibla Direction'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(isUrdu, primaryColor, cardColor, textSecondary),
    );
  }

  Widget _buildBody(bool isUrdu, Color primaryColor, Color cardColor, Color textSecondary) {
    if (_isLoading) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: primaryColor),
        const SizedBox(height: 16),
        Text(isUrdu ? 'قبلہ کی سمت معلوم کی جا رہی ہے...' : 'Determining Qibla direction...',
            style: TextStyle(color: textSecondary)),
      ]));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage, style: TextStyle(color: textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkPermissionsAndGetLocation,
            child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Retry'),
          ),
        ]),
      ));
    }

    if (!_hasLocation) {
      return Center(child: Text(isUrdu ? 'لوکیشن حاصل نہیں ہو سکی' : 'Unable to get location'));
    }

    // ── Both sections in one scroll view ─────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // ════════════════════════════════════════════════════════════════
          // SECTION 1 — existing Qibla compass (unchanged)
          // ════════════════════════════════════════════════════════════════
          const SizedBox(height: 24),
          Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            color: cardColor,
            child: Container(
              width: 260, height: 260,
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: QiblaCompassPainter(
                    arrowAngleRad: _animation.value,
                    deviceHeadingDeg: _deviceHeading,
                    primaryColor: primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info cards row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoCard(isUrdu ? 'قبلہ' : 'Qibla', '${_qiblaBearing.toStringAsFixed(0)}°', primaryColor, cardColor, textSecondary),
              const SizedBox(width: 16),
              _infoCard(isUrdu ? 'فون کی سمت' : 'Heading', '${_deviceHeading.toStringAsFixed(0)}°', Colors.teal, cardColor, textSecondary),
            ],
          ),
          const SizedBox(height: 16),

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

          const SizedBox(height: 32),

          // ════════════════════════════════════════════════════════════════
          // SECTION 2 — Nearest Mosque Finder
          // ════════════════════════════════════════════════════════════════
          _buildMosqueFinder(isUrdu, primaryColor, cardColor, textSecondary),
        ],
      ),
    );
  }

  // ── Mosque finder section ────────────────────────────────────────────────

  Widget _buildMosqueFinder(bool isUrdu, Color primaryColor, Color cardColor, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(
                isUrdu ? 'قریبی مسجد' : 'Nearest Mosques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const Spacer(),
              // Badge showing count
              if (_mosquesLoaded && _mosques.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_mosques.length}', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              isUrdu ? '5 کلومیٹر کے اندر مساجد' : 'Mosques within 5 km of you',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // ── Find button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isFindingMosques ? null : _findNearbyMosques,
              icon: _isFindingMosques
                  ? SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.mosque_rounded, size: 20),
              label: Text(
                _isFindingMosques
                    ? (isUrdu ? 'تلاش جاری ہے...' : 'Searching...')
                    : (isUrdu ? 'قریبی مسجد تلاش کریں' : 'Find Mosques Near Me'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Error state ────────────────────────────────────────────────
          if (_mosqueError.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_mosqueError, style: const TextStyle(color: Colors.orange, fontSize: 13))),
              ]),
            ),

          // ── Mosque list ────────────────────────────────────────────────
          if (_mosques.isNotEmpty) ...[
            // Closest mosque highlight card
            _buildClosestMosqueCard(_mosques.first, primaryColor, isDark, isUrdu),
            const SizedBox(height: 10),
            // Rest of the list
            ..._mosques.skip(1).toList().asMap().entries.map((entry) {
              return _buildMosqueListTile(entry.value, entry.key + 2, primaryColor, cardColor, textSecondary, isDark, isUrdu);
            }),
          ],
        ],
      ),
    );
  }

  /// Highlighted card for the nearest mosque
  Widget _buildClosestMosqueCard(_Mosque mosque, Color primaryColor, bool isDark, bool isUrdu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primaryColor.withOpacity(0.6), primaryColor.withOpacity(0.35)]
              : [primaryColor.withOpacity(0.85), primaryColor.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Text('🕌', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUrdu ? 'سب سے قریب' : 'Closest',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Text(mosque.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                const SizedBox(width: 3),
                Text(_formatDistance(mosque.distanceKm),
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  /// Regular list tile for other mosques
  Widget _buildMosqueListTile(_Mosque mosque, int rank, Color primaryColor,
      Color cardColor, Color textSecondary, bool isDark, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.08)),
      ),
      child: Row(children: [
        // Rank bubble
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(isDark ? 0.25 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text('$rank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mosque.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_rounded, color: primaryColor, size: 12),
              const SizedBox(width: 3),
              Text(_formatDistance(mosque.distanceKm),
                  style: TextStyle(fontSize: 12, color: textSecondary)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Info card (unchanged) ────────────────────────────────────────────────

  Widget _infoCard(String label, String value, Color valueColor, Color cardColor, Color textSecondary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QiblaCompassPainter — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class QiblaCompassPainter extends CustomPainter {
  final double arrowAngleRad;
  final double deviceHeadingDeg;
  final Color primaryColor;

  QiblaCompassPainter({required this.arrowAngleRad, required this.deviceHeadingDeg, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(center, radius, Paint()..color = Colors.grey.withOpacity(0.08)..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius, Paint()..color = Colors.grey.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final tickPaint = Paint()..color = Colors.grey.withOpacity(0.4)..strokeWidth = 1;
    for (int i = 0; i < 36; i++) {
      double angle = i * 10 * pi / 180;
      bool isMajor = i % 9 == 0;
      double inner = isMajor ? radius - 14 : radius - 8;
      canvas.drawLine(
        Offset(center.dx + inner * sin(angle), center.dy - inner * cos(angle)),
        Offset(center.dx + radius * sin(angle), center.dy - radius * cos(angle)),
        tickPaint..strokeWidth = isMajor ? 2.0 : 1.0,
      );
    }

    _drawCardinalLabel(canvas, center, radius, 'N', 0, Colors.red);
    _drawCardinalLabel(canvas, center, radius, 'E', pi / 2, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'S', pi, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'W', 3 * pi / 2, Colors.grey);

    final arrowLength = radius * 0.62;
    final tailLength = radius * 0.30;
    final tip = Offset(center.dx + arrowLength * sin(arrowAngleRad), center.dy - arrowLength * cos(arrowAngleRad));
    final tail = Offset(center.dx - tailLength * sin(arrowAngleRad), center.dy + tailLength * cos(arrowAngleRad));

    canvas.drawLine(tail, tip, Paint()..color = primaryColor..strokeWidth = 6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    final perpAngle = arrowAngleRad + pi / 2;
    const wingSpread = 12.0;
    const wingBack = 22.0;
    final leftWing = Offset(tip.dx - wingBack * sin(arrowAngleRad) + wingSpread * sin(perpAngle), tip.dy + wingBack * cos(arrowAngleRad) - wingSpread * cos(perpAngle));
    final rightWing = Offset(tip.dx - wingBack * sin(arrowAngleRad) - wingSpread * sin(perpAngle), tip.dy + wingBack * cos(arrowAngleRad) + wingSpread * cos(perpAngle));
    final headPath = Path()..moveTo(tip.dx, tip.dy)..lineTo(leftWing.dx, leftWing.dy)..lineTo(rightWing.dx, rightWing.dy)..close();
    canvas.drawPath(headPath, Paint()..color = primaryColor);

    canvas.drawCircle(tail, 5, Paint()..color = primaryColor.withOpacity(0.5));

    final tp = TextPainter(text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 18)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(tip.dx - tp.width / 2, tip.dy - tp.height / 2 - 14));

    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawCardinalLabel(Canvas canvas, Offset center, double radius, String label, double angle, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelRadius = radius - 22;
    tp.paint(canvas, Offset(center.dx + labelRadius * sin(angle) - tp.width / 2, center.dy - labelRadius * cos(angle) - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter old) =>
      old.arrowAngleRad != arrowAngleRad || old.deviceHeadingDeg != deviceHeadingDeg;
}