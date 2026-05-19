import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../providers/language_provider.dart';
import 'mosque_map_screen.dart';

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

  // Compass stream subscription
  dynamic _compassSubscription;

  late AnimationController _animController;
  late Animation<double> _animation;
  double _lastArrowAngle = 0;

  // ValueNotifier for heading — prevents full-tree rebuilds on every sensor tick.
  // Only the compass widget listens to this, not the entire screen.
  final ValueNotifier<double> _headingNotifier = ValueNotifier<double>(0.0);

  bool _isAligned = false;
  double? _lastHeading;

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
      duration: const Duration(milliseconds: 180), // smoother transition duration
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _checkPermissionsAndGetLocation();
    _startCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _animController.dispose();
    _headingNotifier.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sensors
  // ─────────────────────────────────────────────────────────────────────────

  // ── flutter_compass: uses Android SensorManager.getOrientation() ──────────
  // This is the correct way — handles all tilt/orientation automatically.

  void _startCompass() {
    // Check if compass is available on this device
    if (FlutterCompass.events == null) {
      setState(() => _errorMessage = 'Compass sensor not available on this device.');
      return;
    }

    _compassSubscription = FlutterCompass.events!.listen((CompassEvent event) {
      final heading = event.heading;
      if (heading == null || !mounted) return;

      // Apply Exponential Moving Average (EMA) filter to smooth out sensor micro-jitter
      final smoothedHeading = _lastHeading == null
          ? heading
          : _lastHeading! + 0.18 * (heading - _lastHeading!);
      _lastHeading = smoothedHeading;

      // Update heading value
      _deviceHeading = (smoothedHeading + 360) % 360;

      // Target angle relative to device's top
      final targetAngle = (_qiblaBearing - _deviceHeading) * pi / 180;
      double diff = targetAngle - _lastArrowAngle;
      while (diff > pi)  diff -= 2 * pi;
      while (diff < -pi) diff += 2 * pi;

      // Skip tiny changes to avoid micro-jitters
      if (diff.abs() < 0.005) return;

      final newTarget = _lastArrowAngle + diff;

      _animation = Tween<double>(begin: _lastArrowAngle, end: newTarget).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0);
      _lastArrowAngle = newTarget;

      // Alignment check (within ±5.7 degrees)
      double normDiff = targetAngle % (2 * pi);
      if (normDiff > pi) normDiff -= 2 * pi;
      if (normDiff < -pi) normDiff += 2 * pi;
      final bool aligned = normDiff.abs() < 0.1;

      if (aligned != _isAligned) {
        setState(() {
          _isAligned = aligned;
        });
        if (aligned) {
          HapticFeedback.mediumImpact();
        }
      }

      // Update heading via ValueNotifier
      _headingNotifier.value = _deviceHeading;
    });
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
      // Use higher frequency and forced manager for initial lock
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
        ),
      ).timeout(const Duration(seconds: 15), onTimeout: () async {
        return await Geolocator.getLastKnownPosition() ?? Position(
          latitude: 24.8934, longitude: 67.0894, // Fallback to Karachi (Bahria University area)
          timestamp: DateTime.now(), accuracy: 0, altitude: 0,
          heading: 0, speed: 0, speedAccuracy: 0,
          altitudeAccuracy: 0, headingAccuracy: 0,
        );
      });
      _currentPosition = pos;
      _calculateQiblaBearing(pos.latitude, pos.longitude);
      if (mounted) setState(() { _hasLocation = true; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Failed to get location: $e'; });
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

  // ── Manual Location Override with Suggestions ───────────────────────────
  Future<void> _setManualLocation(String query) async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'SmartNamazCompanion/1.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() { _isLoading = false; _errorMessage = 'No locations found. Try "Karachi".'; });
          return;
        }

        setState(() => _isLoading = false);

        // Show suggestions if multiple found, otherwise pick first
        if (data.length > 1) {
          _showLocationPicker(data);
        } else {
          _applyLocation(data[0]);
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Search failed: $e'; });
    }
  }

  void _showLocationPicker(List<dynamic> suggestions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select exact location:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, i) {
                  final s = suggestions[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(s['display_name'].split(',')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _applyLocation(s);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyLocation(Map<String, dynamic> locationData) {
    final lat = double.parse(locationData['lat']);
    final lon = double.parse(locationData['lon']);

    _currentPosition = Position(
      latitude: lat, longitude: lon,
      timestamp: DateTime.now(), accuracy: 0, altitude: 0,
      heading: 0, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    );

    _calculateQiblaBearing(lat, lon);
    setState(() => _hasLocation = true);
    _findNearbyMosques();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // Mosque finder — multi-API waterfall (Nominatim → Overpass mirrors)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _findNearbyMosques() async {
    if (_currentPosition == null) {
      setState(() => _mosqueError = 'Location not available. Please retry Qibla detection first.');
      return;
    }
    setState(() { _isFindingMosques = true; _mosqueError = ''; _mosques = []; });

    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;

    List<_Mosque>? result;

    // Gradually expanding radius: 3km, 10km, 25km, 50km
    final List<double> deltas = [0.027, 0.09, 0.22, 0.45];
    final List<int> overpassRadii = [3000, 10000, 25000, 50000];

    for (int i = 0; i < deltas.length; i++) {
      final delta = deltas[i];
      final radius = overpassRadii[i];

      print('[QiblaMosques] Querying at radius: ${radius / 1000} km...');
      result = await _fetchViaNominatim(lat, lon, delta);

      if (result == null || result.isEmpty) {
        result = await _fetchViaOverpass(lat, lon, 'https://overpass-api.de/api/interpreter', radius);
      }
      if (result == null || result.isEmpty) {
        result = await _fetchViaOverpass(lat, lon, 'https://overpass.kumi.systems/api/interpreter', radius);
      }

      if (result != null && result.length >= 3) {
        print('[QiblaMosques] Found sufficient mosques (${result.length}) at radius: ${radius / 1000} km.');
        break;
      }
    }

    if (result != null) {
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Limit to closest 4 mosques for sparse list display
      final limit = result.length > 4 ? 4 : result.length;
      setState(() {
        _mosques = result!.take(limit).toList();
        _mosquesLoaded = true;
        _isFindingMosques = false;
        _mosqueError = result!.isEmpty ? 'No mosques found nearby.' : '';
      });
    } else {
      setState(() {
        _isFindingMosques = false;
        _mosqueError =
            'Could not fetch mosque data.\n\n'
            'Possible causes:\n'
            '• No internet connection\n'
            '• Location services blocked\n'
            '• OSM servers temporarily unavailable\n\n'
            'Please try again in a few seconds.';
      });
    }
  }

  /// Source 1: Nominatim geocoding — lightweight GET, usually fastest
  Future<List<_Mosque>?> _fetchViaNominatim(double lat, double lon, double delta) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&q=mosque&bounded=1'
        '&viewbox=${lon-delta},${lat+delta},${lon+delta},${lat-delta}'
        '&limit=15&addressdetails=0',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'SmartNamazCompanion/1.0',
        'Accept-Language': 'en,ur',
      }).timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) return null;

      final raw = jsonDecode(resp.body) as List<dynamic>;
      final List<_Mosque> list = [];
      for (final item in raw) {
        final mLat = double.tryParse(item['lat']?.toString() ?? '');
        final mLon = double.tryParse(item['lon']?.toString() ?? '');
        if (mLat == null || mLon == null) continue;
        final dist = _haversineKm(lat, lon, mLat, mLon);
        final nameParts = (item['display_name'] as String? ?? 'Mosque').split(',');
        final name = nameParts.first.trim().isEmpty ? 'Mosque' : nameParts.first.trim();
        list.add(_Mosque(name: name, lat: mLat, lon: mLon, distanceKm: dist));
      }
      // deduplicate
      final seen = <String>{};
      final deduped = list.where((m) => seen.add('${m.name}_${m.lat.toStringAsFixed(3)}')).toList();
      deduped.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return deduped.toList();
    } catch (e) {
      print('[MosqueFinder] Nominatim failed: $e');
      return null;
    }
  }

  /// Source 2+: Overpass API mirrors — richer data, slower
  Future<List<_Mosque>?> _fetchViaOverpass(double lat, double lon, String endpoint, int radiusMeters) async {
    try {
      final query =
          '[out:json][timeout:20];'
          '('
          'node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);'
          'way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);'
          'node["amenity"="mosque"](around:$radiusMeters,$lat,$lon);'
          'way["amenity"="mosque"](around:$radiusMeters,$lat,$lon);'
          ');out center 20;';

      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      ).timeout(const Duration(seconds: 22));

      if (resp.statusCode != 200) return null;

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map || decoded['elements'] is! List) return null;

      final List<_Mosque> list = [];
      for (final el in decoded['elements'] as List) {
        double? mLat, mLon;
        if (el['type'] == 'node') {
          mLat = (el['lat'] as num?)?.toDouble();
          mLon = (el['lon'] as num?)?.toDouble();
        } else if (el['type'] == 'way' && el['center'] != null) {
          mLat = (el['center']['lat'] as num?)?.toDouble();
          mLon = (el['center']['lon'] as num?)?.toDouble();
        }
        if (mLat == null || mLon == null) continue;
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name =
            (tags['name:ur'] as String?)?.trim().isNotEmpty == true ? tags['name:ur'] as String :
            (tags['name'] as String?)?.trim().isNotEmpty == true ? tags['name'] as String :
            (tags['name:en'] as String?)?.trim().isNotEmpty == true ? tags['name:en'] as String :
            'Mosque';
        final dist = _haversineKm(lat, lon, mLat, mLon);
        list.add(_Mosque(name: name, lat: mLat, lon: mLon, distanceKm: dist));
      }
      final seen = <String>{};
      return list.where((m) => seen.add('${m.name}_${m.lat.toStringAsFixed(3)}')).toList();
    } catch (e) {
      print('[MosqueFinder] Overpass ($endpoint) failed: $e');
      return null;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: Text(isUrdu ? 'دوبارہ کوشش کریں' : 'Retry GPS'),
          ),
          const SizedBox(height: 12),
          Text(isUrdu ? 'یا دستی طور پر شہر تلاش کریں:' : 'Or search city manually:', style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 8),
          TextField(
            onSubmitted: (val) => _setManualLocation(val),
            decoration: InputDecoration(
              hintText: isUrdu ? 'شہر کا نام لکھیں (مثلاً کراچی)' : 'Enter city (e.g. Karachi)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
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
            elevation: _isAligned ? 12 : 4,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(
                color: _isAligned
                    ? const Color(0xFFD4AF37).withOpacity(0.8) // Golden border when aligned!
                    : Colors.transparent,
                width: 2.0
              ),
            ),
            color: cardColor,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 260, height: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: _isAligned
                    ? LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E2B1E), cardColor]
                            : [const Color(0xFFECF7EC), cardColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                boxShadow: _isAligned
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(isDark ? 0.15 : 0.25),
                          blurRadius: 24,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: QiblaCompassPainter(
                    arrowAngleRad: _animation.value,
                    deviceHeadingDeg: _deviceHeading,
                    primaryColor: _isAligned ? const Color(0xFFD4AF37) : primaryColor,
                    isAligned: _isAligned,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info cards row — uses ValueListenableBuilder to avoid rebuilding the whole screen
          ValueListenableBuilder<double>(
            valueListenable: _headingNotifier,
            builder: (context, heading, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoCard(isUrdu ? 'قبلہ' : 'Qibla', '${_qiblaBearing.toStringAsFixed(0)}°', primaryColor, cardColor, textSecondary),
                const SizedBox(width: 16),
                _infoCard(isUrdu ? 'فون کی سمت' : 'Heading', '${heading.toStringAsFixed(0)}°', Colors.teal, cardColor, textSecondary),
              ],
            ),
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

          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(isUrdu ? 'مقام تبدیل کریں' : 'Change Location'),
                  content: TextField(
                    onSubmitted: (val) {
                      Navigator.pop(ctx);
                      _setManualLocation(val);
                    },
                    decoration: InputDecoration(
                      hintText: isUrdu ? 'شہر کا نام لکھیں' : 'Enter city (e.g. Karachi)',
                    ),
                  ),
                ),
              );
            },
            child: Text(isUrdu ? 'مقام غلط ہے؟ دستی تلاش کریں' : 'Wrong location? Search manually', style: const TextStyle(fontSize: 12)),
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
              isUrdu ? 'قریبی مساجد' : 'Nearest mosques to you',
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(isUrdu ? 'خرابی' : 'Could not load mosques',
                      style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text(_mosqueError, style: TextStyle(color: Colors.orange.shade700, fontSize: 12, height: 1.5)),
              ]),
            ),

          // ── Mosque list ────────────────────────────────────────────────
          if (_mosques.isNotEmpty) ...[
            // ── View on Map button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final mapItems = _mosques.map((m) => MosqueMapItem(
                    name: m.name,
                    lat: m.lat,
                    lon: m.lon,
                    distanceKm: m.distanceKm,
                  )).toList();
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                    MosqueMapScreen(
                      userLat: _currentPosition!.latitude,
                      userLon: _currentPosition!.longitude,
                      initialMosques: mapItems,
                    )));
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: Text(
                  isUrdu ? 'نقشے پر دیکھیں' : 'View on Map with Routes',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            child: const Icon(Icons.mosque_rounded, size: 28, color: Colors.white),
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

class QiblaCompassPainter extends CustomPainter {
  final double arrowAngleRad;
  final double deviceHeadingDeg;
  final Color primaryColor;
  final bool isAligned;

  QiblaCompassPainter({
    required this.arrowAngleRad,
    required this.deviceHeadingDeg,
    required this.primaryColor,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Draw the backing concentric circles in premium olive-gold tones
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isAligned
              ? const Color(0xFFD4AF37).withOpacity(0.08)
              : primaryColor.withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Multiple concentric circles for structured spiritual design
    final borderPaint = Paint()
      ..color = isAligned
          ? const Color(0xFFD4AF37).withOpacity(0.4)
          : Colors.grey.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius * 0.85, borderPaint..color = borderPaint.color.withOpacity(0.12));
    canvas.drawCircle(center, radius * 0.5, borderPaint..color = borderPaint.color.withOpacity(0.06));

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

    _drawCardinalLabel(canvas, center, radius, 'N', 0, isAligned ? const Color(0xFFD4AF37) : Colors.red);
    _drawCardinalLabel(canvas, center, radius, 'E', pi / 2, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'S', pi, Colors.grey);
    _drawCardinalLabel(canvas, center, radius, 'W', 3 * pi / 2, Colors.grey);

    final arrowLength = radius * 0.65;
    final tailLength = radius * 0.25;
    final tip = Offset(center.dx + arrowLength * sin(arrowAngleRad), center.dy - arrowLength * cos(arrowAngleRad));
    final tail = Offset(center.dx - tailLength * sin(arrowAngleRad), center.dy + tailLength * cos(arrowAngleRad));

    // Outer highlight needle shadow when aligned
    if (isAligned) {
      canvas.drawLine(
        tail,
        tip,
        Paint()
          ..color = const Color(0xFFD4AF37).withOpacity(0.25)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawLine(tail, tip, Paint()..color = primaryColor..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);

    final perpAngle = arrowAngleRad + pi / 2;
    const wingSpread = 10.0;
    const wingBack = 18.0;
    final leftWing = Offset(tip.dx - wingBack * sin(arrowAngleRad) + wingSpread * sin(perpAngle), tip.dy + wingBack * cos(arrowAngleRad) - wingSpread * cos(perpAngle));
    final rightWing = Offset(tip.dx - wingBack * sin(arrowAngleRad) - wingSpread * sin(perpAngle), tip.dy + wingBack * cos(arrowAngleRad) + wingSpread * cos(perpAngle));
    final headPath = Path()..moveTo(tip.dx, tip.dy)..lineTo(leftWing.dx, leftWing.dy)..lineTo(rightWing.dx, rightWing.dy)..close();
    canvas.drawPath(headPath, Paint()..color = primaryColor);

    canvas.drawCircle(tail, 4, Paint()..color = primaryColor.withOpacity(0.5));

    // Draw a premium custom-drawn Kaaba cube instead of an emoji!
    final double kaabaSize = 16.0;
    final kaabaCenter = Offset(tip.dx, tip.dy - 18);
    final kaabaRect = Rect.fromCenter(center: kaabaCenter, width: kaabaSize, height: kaabaSize);

    // Draw the main black cube body
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(3)),
      Paint()..color = Colors.black..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(3)),
      Paint()..color = isAligned ? const Color(0xFFD4AF37).withOpacity(0.5) : Colors.grey.shade800..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );

    // Draw the golden band (Kiswa) near the top (top 20% of the cube)
    final goldBandRect = Rect.fromLTWH(
      kaabaRect.left,
      kaabaRect.top + 3.0,
      kaabaRect.width,
      2.5,
    );
    canvas.drawRect(
      goldBandRect,
      Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill, // Golden Kiswa color
    );

    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
    canvas.drawCircle(center, 7, Paint()..color = isAligned ? const Color(0xFFD4AF37) : Colors.grey..style = PaintingStyle.stroke..strokeWidth = 1.5);
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
      old.arrowAngleRad != arrowAngleRad || old.deviceHeadingDeg != deviceHeadingDeg || old.isAligned != isAligned;
}
