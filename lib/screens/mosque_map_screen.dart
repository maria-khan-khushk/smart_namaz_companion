import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mosque data model for the map
// ─────────────────────────────────────────────────────────────────────────────
class MosqueMapItem {
  final String name;
  final double lat;
  final double lon;
  final double distanceKm;
  List<LatLng> routePoints;
  double? routeDistanceKm;
  double? routeDurationMin;
  bool isLoadingRoute;

  MosqueMapItem({
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    this.routePoints = const [],
    this.routeDistanceKm,
    this.routeDurationMin,
    this.isLoadingRoute = false,
  });
}

class MosqueMapScreen extends StatefulWidget {
  final double userLat;
  final double userLon;
  final List<MosqueMapItem>? initialMosques;

  const MosqueMapScreen({
    super.key,
    this.userLat = 24.8934, // Default to Karachi (Bahria University area)
    this.userLon = 67.0894,
    this.initialMosques,
  });

  @override
  State<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends State<MosqueMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<MosqueMapItem> _mosques = [];
  bool _isLoading = true;
  String _error = '';
  int _selectedIndex = -1; // -1 = none selected, show all
  bool _showList = true;
  String _travelMode = 'foot'; // 'foot' or 'car'
  String _userAddress = '';
  bool _isFetchingAddress = false;

  // Custom location state
  late double _currentLat;
  late double _currentLon;
  bool _isUsingCustomLocation = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  Timer? _addressDebounce;

  // Harmonized Slate-and-Olive Route & Marker Palette
  static const _routeColors = [
    Color(0xFF5A6B53), // Slate-olive dark
    Color(0xFF7B8E72), // Slate-olive medium
    Color(0xFF9CB093), // Slate-olive light
    Color(0xFF4A5644), // Slate-olive deep dark
  ];

  @override
  void initState() {
    super.initState();
    _currentLat = widget.userLat;
    _currentLon = widget.userLon;
    if (widget.initialMosques != null && widget.initialMosques!.isNotEmpty) {
      _mosques = widget.initialMosques!;
      _isLoading = false;
      _fetchAllRoutes();
    } else {
      _loadMosques();
    }
    _fetchUserAddress();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateLocation(double lat, double lon, {bool isCustom = true}) {
    setState(() {
      _currentLat = lat;
      _currentLon = lon;
      _isUsingCustomLocation = isCustom;
      _selectedIndex = -1;
      for (final m in _mosques) { m.routePoints = []; m.routeDistanceKm = null; m.routeDurationMin = null; }
    });
    _loadMosques();
    // Debounce address fetching to avoid spamming Nominatim
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 1500), _fetchUserAddress);
  }

  Future<void> _fetchUserAddress() async {
    setState(() => _isFetchingAddress = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$_currentLat&lon=$_currentLon&zoom=18&addressdetails=1';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'SmartNamazCompanion/1.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _userAddress = data['display_name'] ?? 'Address not found';
          _isFetchingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _userAddress = 'Error fetching address';
        _isFetchingAddress = false;
      });
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lon) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ── Search Locations ───────────────────────────────────────────────────────
  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (query.trim().length > 2) _performSearch(query);
      else setState(() => _searchResults = []);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'SmartNamazCompanion/1.0'});
      if (resp.statusCode == 200) {
        setState(() => _searchResults = jsonDecode(resp.body));
      }
    } catch (_) {}
    setState(() => _isSearching = false);
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final name = result['display_name'];

    _searchController.clear();
    setState(() {
      _searchResults = [];
      _userAddress = name;
    });

    _updateLocation(lat, lon, isCustom: true);
    _mapController.move(LatLng(lat, lon), 14.0);
    FocusScope.of(context).unfocus();
  }

  // ── Load mosques from Overpass/Nominatim ──────────────────────────────────
  // ── Load mosques from Overpass/Nominatim with Dynamic Intelligent Radius ──
  Future<void> _loadMosques() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      print('[MosqueMap] Searching for mosques near $_currentLat, $_currentLon with dynamic radius');
      List<MosqueMapItem>? result;

      // Gradually expanding radius: 3km, 10km, 25km, 50km
      final List<double> deltas = [0.027, 0.09, 0.22, 0.45];
      final List<int> overpassRadii = [3000, 10000, 25000, 50000];

      for (int i = 0; i < deltas.length; i++) {
        final delta = deltas[i];
        final radius = overpassRadii[i];

        print('[MosqueMap] Querying at radius: ${radius / 1000} km...');
        result = await _fetchNominatim(_currentLat, _currentLon, delta);

        if (result == null || result.isEmpty) {
          result = await _fetchOverpass(_currentLat, _currentLon, 'https://overpass-api.de/api/interpreter', radius);
        }
        if (result == null || result.isEmpty) {
          result = await _fetchOverpass(_currentLat, _currentLon, 'https://overpass.kumi.systems/api/interpreter', radius);
        }

        if (result != null && result.length >= 3) {
          print('[MosqueMap] Found sufficient mosques (${result.length}) at radius: ${radius / 1000} km.');
          break;
        }
      }

      if (result == null || result.isEmpty) {
        print('[MosqueMap] All sources failed to find mosques.');
        setState(() { _isLoading = false; _error = 'No mosques found nearby within 50km.'; });
        return;
      }

      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      // Limit to closest 4 mosques for sparse, clean visual representation
      final limit = result.length > 4 ? 4 : result.length;
      setState(() {
        _mosques = result!.take(limit).toList();
        _isLoading = false;
      });

      _fetchAllRoutes();
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Failed to load mosques: $e'; });
    }
  }

  Future<List<MosqueMapItem>?> _fetchOverpass(double lat, double lon, String endpoint, int radiusMeters) async {
    try {
      final query = '[out:json][timeout:25];'
          '('
          'node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);'
          'way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$lat,$lon);'
          'node["amenity"="mosque"](around:$radiusMeters,$lat,$lon);'
          'way["amenity"="mosque"](around:$radiusMeters,$lat,$lon);'
          'node["building"="mosque"](around:$radiusMeters,$lat,$lon);'
          'way["building"="mosque"](around:$radiusMeters,$lat,$lon);'
          ');out center 20;';
      final resp = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      ).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map || decoded['elements'] is! List) return null;
      final List<MosqueMapItem> list = [];
      for (final el in decoded['elements'] as List) {
        double? mLat, mLon;
        if (el['type'] == 'node') { mLat = (el['lat'] as num?)?.toDouble(); mLon = (el['lon'] as num?)?.toDouble(); }
        else if (el['type'] == 'way' && el['center'] != null) { mLat = (el['center']['lat'] as num?)?.toDouble(); mLon = (el['center']['lon'] as num?)?.toDouble(); }
        if (mLat == null || mLon == null) continue;
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name = (tags['name:ur'] as String?)?.trim().isNotEmpty == true ? tags['name:ur'] as String
            : (tags['name'] as String?)?.trim().isNotEmpty == true ? tags['name'] as String
            : (tags['name:en'] as String?)?.trim().isNotEmpty == true ? tags['name:en'] as String : 'Mosque';
        list.add(MosqueMapItem(name: name, lat: mLat, lon: mLon, distanceKm: _haversineKm(lat, lon, mLat, mLon)));
      }
      final seen = <String>{};
      return list.where((m) => seen.add('${m.name}_${m.lat.toStringAsFixed(3)}')).toList();
    } catch (_) { return null; }
  }

  Future<List<MosqueMapItem>?> _fetchNominatim(double lat, double lon, double delta) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search'
          '?format=json&q=mosque&bounded=1'
          '&viewbox=${lon - delta},${lat + delta},${lon + delta},${lat - delta}'
          '&limit=15&addressdetails=0');
      final resp = await http.get(uri, headers: {'User-Agent': 'SmartNamazCompanion/1.0'}).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return null;
      final raw = jsonDecode(resp.body) as List;
      return raw.map((item) {
        final mLat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
        final mLon = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
        final nameParts = (item['display_name'] as String? ?? 'Mosque').split(',');
        return MosqueMapItem(name: nameParts.first.trim().isEmpty ? 'Mosque' : nameParts.first.trim(),
            lat: mLat, lon: mLon, distanceKm: _haversineKm(lat, lon, mLat, mLon));
      }).toList();
    } catch (_) { return null; }
  }

  // ── OSRM Routing ─────────────────────────────────────────────────────────
  /// Only load routes for the nearest 3 mosques initially.
  /// Routes for other mosques are loaded lazily when selected.
  Future<void> _fetchAllRoutes() async {
    final limit = _mosques.length < 3 ? _mosques.length : 3;
    final futures = <Future>[];
    for (int i = 0; i < limit; i++) {
      futures.add(_fetchRoute(i));
    }
    await Future.wait(futures);
  }

  Future<void> _fetchRoute(int index) async {
    if (index < 0 || index >= _mosques.length) return;
    final m = _mosques[index];
    // Skip if route already loaded
    if (m.routePoints.isNotEmpty) return;
    m.isLoadingRoute = true;
    if (mounted) setState(() {});
    try {
      final profile = _travelMode == 'car' ? 'driving' : 'foot';
      final url = 'https://router.project-osrm.org/route/v1/$profile/'
          '$_currentLon,$_currentLat;${m.lon},${m.lat}'
          '?overview=full&geometries=geojson';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final points = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
          final distKm = (route['distance'] as num).toDouble() / 1000;
          final durMin = (route['duration'] as num).toDouble() / 60;
          m.routePoints = points;
          m.routeDistanceKm = distKm;
          m.routeDurationMin = durMin;
        }
      }
    } catch (_) {}
    m.isLoadingRoute = false;
    // Single setState after route finishes (instead of 3 separate calls)
    if (mounted) setState(() {});
  }


  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _selectMosque(int index) {
    setState(() => _selectedIndex = _selectedIndex == index ? -1 : index);
    if (_selectedIndex >= 0) {
      final m = _mosques[_selectedIndex];
      _mapController.move(LatLng((_currentLat + m.lat) / 2, (_currentLon + m.lon) / 2), 14.5);
      // Lazy-load route for this mosque if not already loaded
      if (m.routePoints.isEmpty && !m.isLoadingRoute) {
        _fetchRoute(_selectedIndex);
      }
    } else {
      _mapController.move(LatLng(_currentLat, _currentLon), 11.0);
    }
  }

  void _switchTravelMode(String mode) {
    if (mode == _travelMode) return;
    setState(() { _travelMode = mode; for (final m in _mosques) { m.routePoints = []; m.routeDistanceKm = null; m.routeDurationMin = null; } });
    _fetchAllRoutes();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isUrdu = Provider.of<LanguageProvider>(context).isUrdu;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: _circleButton(Icons.arrow_back_rounded, () => Navigator.pop(context), isDark),
        title: _buildSearchBar(isDark, isUrdu, primaryColor),
        centerTitle: true,
        actions: [
          const SizedBox(width: 48), // Balancing leading
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(isUrdu ? 'نقشہ لوڈ ہو رہا ہے...' : 'Loading map...', style: TextStyle(color: Colors.grey.shade600)),
            ]))
          : _error.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(_error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(onPressed: _loadMosques, icon: const Icon(Icons.refresh_rounded), label: Text(isUrdu ? 'دوبارہ کوشش' : 'Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white)),
                ])))
              : Stack(children: [
                  _buildMap(primaryColor, isDark),
                  // Search Results Overlay
                  if (_searchResults.isNotEmpty) Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 16, right: 16,
                    child: _buildSearchResultsList(isDark, primaryColor),
                  ),
                  // Travel mode toggle
                  Positioned(top: MediaQuery.of(context).padding.top + 70, right: 12, child: _buildTravelToggle(isDark, primaryColor)),
                  // Recenter button
                  Positioned(bottom: _showList ? 290 : 24, right: 12, child: _circleButton(Icons.my_location_rounded, () => _mapController.move(LatLng(widget.userLat, widget.userLon), 14.0), isDark, size: 44)),
                  // List Toggle
                  Positioned(top: MediaQuery.of(context).padding.top + 70, left: 12, child: _circleButton(_showList ? Icons.map_rounded : Icons.list_rounded, () => setState(() => _showList = !_showList), isDark, size: 44)),
                  // Bottom mosque list
                  if (_showList) Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomSheet(primaryColor, isDark, isUrdu)),
                ]),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, bool isDark, {double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: size * 0.5, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, bool isUrdu, Color primaryColor) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: isUrdu ? 'جگہ تلاش کریں...' : 'Search location...',
          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
          suffixIcon: _isSearching
            ? Container(width: 20, height: 20, padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
            : (_searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchResults = []); }) : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(bool isDark, Color primaryColor) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        itemBuilder: (ctx, i) {
          final res = _searchResults[i];
          return ListTile(
            dense: true,
            leading: Icon(Icons.place_rounded, color: primaryColor, size: 18),
            title: Text(res['display_name'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _selectSearchResult(res),
          );
        },
      ),
    );
  }

  Widget _buildTravelToggle(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey.shade900 : Colors.white).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _travelChip(Icons.directions_walk_rounded, 'foot', primaryColor, isDark),
        const SizedBox(width: 2),
        _travelChip(Icons.directions_car_rounded, 'car', primaryColor, isDark),
      ]),
    );
  }

  Widget _travelChip(IconData icon, String mode, Color primaryColor, bool isDark) {
    final isActive = _travelMode == mode;
    return GestureDetector(
      onTap: () => _switchTravelMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 18, color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.black45)),
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────
  Widget _buildMap(Color primaryColor, bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_currentLat, _currentLon),
        initialZoom: 11.0,
        onLongPress: (hit, point) => _updateLocation(point.latitude, point.longitude, isCustom: true),
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.smartnamazcompanion',
        ),
        // Route polylines
        PolylineLayer(polylines: _buildRoutePolylines()),
        // Markers
        MarkerLayer(markers: _buildMarkers(primaryColor)),
      ],
    );
  }

  List<Polyline> _buildRoutePolylines() {
    final lines = <Polyline>[];
    for (int i = 0; i < _mosques.length; i++) {
      final m = _mosques[i];
      if (m.routePoints.isEmpty) continue;
      final isSelected = _selectedIndex == i;
      if (_selectedIndex >= 0 && !isSelected) continue; // hide non-selected routes when one is selected
      final color = _routeColors[i % _routeColors.length];
      lines.add(Polyline(
        points: m.routePoints,
        strokeWidth: isSelected ? 5.0 : 3.5,
        color: isSelected ? color : color.withOpacity(0.5),
        borderStrokeWidth: isSelected ? 2.0 : 0,
        borderColor: Colors.white.withOpacity(0.4),
      ));
    }
    return lines;
  }

  List<Marker> _buildMarkers(Color primaryColor) {
    final markers = <Marker>[];
    // User marker
    markers.add(Marker(
      point: LatLng(_currentLat, _currentLon),
      width: 40, height: 40,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isUsingCustomLocation ? Colors.orange : Colors.blue,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: (_isUsingCustomLocation ? Colors.orange : Colors.blue).withOpacity(0.4), blurRadius: 12, spreadRadius: 4)],
        ),
        child: Icon(_isUsingCustomLocation ? Icons.location_on_rounded : Icons.person_rounded, color: Colors.white, size: 20),
      ),
    ));
    // Mosque markers
    for (int i = 0; i < _mosques.length; i++) {
      final m = _mosques[i];
      final isSelected = _selectedIndex == i;
      final color = _routeColors[i % _routeColors.length];
      if (_selectedIndex >= 0 && !isSelected) continue;
      markers.add(Marker(
        point: LatLng(m.lat, m.lon),
        width: isSelected ? 48 : 38, height: isSelected ? 48 : 38,
        child: GestureDetector(
          onTap: () => _selectMosque(i),
          child: Container(
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
            ),
            child: const Center(child: Icon(Icons.mosque_rounded, size: 16, color: Colors.white)),
          ),
        ),
      ));
    }
    return markers;
  }

  // ── Bottom Sheet ──────────────────────────────────────────────────────────
  Widget _buildBottomSheet(Color primaryColor, bool isDark, bool isUrdu) {
    final bgColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(children: [
        // Handle
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Icon(Icons.mosque_rounded, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(isUrdu ? 'قریبی مساجد' : 'Nearby Mosques',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            const Spacer(),
            if (_selectedIndex >= 0) TextButton(onPressed: () => _selectMosque(_selectedIndex),
                child: Text(isUrdu ? 'سب دکھائیں' : 'Show All', style: TextStyle(fontSize: 12, color: primaryColor))),
          ]),
        ),
        // User Location Details
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.my_location_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(isUrdu
                    ? (_isUsingCustomLocation ? 'منتخب مقام' : 'آپ کا مقام')
                    : (_isUsingCustomLocation ? 'Selected Location' : 'Your Location'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                  const Spacer(),
                  if (_isUsingCustomLocation)
                    GestureDetector(
                      onTap: () => _updateLocation(widget.userLat, widget.userLon, isCustom: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(isUrdu ? 'اصل مقام' : 'Reset to GPS', style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text('${_currentLat.toStringAsFixed(4)}, ${_currentLon.toStringAsFixed(4)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 4),
              _isFetchingAddress
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                : Text(_userAddress, style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _mosques.length,
            itemBuilder: (ctx, i) => _buildMosqueTile(i, primaryColor, isDark, isUrdu),
          ),
        ),
      ]),
    );
  }

  Widget _buildMosqueTile(int index, Color primaryColor, bool isDark, bool isUrdu) {
    final m = _mosques[index];
    final isSelected = _selectedIndex == index;
    final color = _routeColors[index % _routeColors.length];

    return GestureDetector(
      onTap: () => _selectMosque(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(isDark ? 0.2 : 0.08) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          // Color indicator + rank
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 11, color: Colors.grey.shade500),
              const SizedBox(width: 2),
              Text(_fmtDist(m.distanceKm), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              if (m.routeDurationMin != null) ...[
                const SizedBox(width: 8),
                Icon(_travelMode == 'car' ? Icons.directions_car_rounded : Icons.directions_walk_rounded, size: 11, color: color),
                const SizedBox(width: 2),
                Text('${m.routeDurationMin!.round()} min', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
              if (m.routeDistanceKm != null) ...[
                const SizedBox(width: 6),
                Text('(${_fmtDist(m.routeDistanceKm!)})', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ]),
          ])),
          if (m.isLoadingRoute) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
          if (!m.isLoadingRoute) ...[
            IconButton(
              icon: Icon(Icons.navigation_rounded, color: color, size: 20),
              onPressed: () => _openInGoogleMaps(m.lat, m.lon),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Navigate in Google Maps',
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ]),
      ),
    );
  }

  String _fmtDist(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
}
