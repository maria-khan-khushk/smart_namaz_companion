import 'package:geolocator/geolocator.dart';

class LocationService {
  // Cache the last known position to avoid repeated GPS lookups
  static Position? _cachedPosition;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentLocation() async {
    // Return cached position if fresh enough (avoids repeated satellite locks)
    if (_cachedPosition != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPosition!;
    }

    try {
      // Use LOW accuracy — prayer times & mosque search only need city-level precision.
      // This resolves via cell tower/Wi-Fi almost instantly instead of waiting 10-30s
      // for a hardware GPS satellite lock.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 8), onTimeout: () async {
        // If even low accuracy times out, try last known position
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
        throw Exception('Location timeout — please try again');
      });

      _cachedPosition = position;
      _cacheTime = DateTime.now();
      return position;
    } catch (e) {
      // Fallback: try last known position before throwing
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _cachedPosition = last;
        _cacheTime = DateTime.now();
        return last;
      }
      rethrow;
    }
  }

  /// Force a fresh GPS lookup (bypasses cache)
  Future<Position> getFreshLocation() async {
    _cachedPosition = null;
    _cacheTime = null;
    return getCurrentLocation();
  }
}