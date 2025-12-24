import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}

/// Singleton LocationService - starts ONCE at app launch, runs FOREVER.
/// Screens consume the stream, they never start/stop tracking.
class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamController<Position>? _controller;
  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;
  bool _isInitialized = false;

  /// The single source of truth for location updates
  Stream<Position> get stream => _controller?.stream ?? const Stream.empty();
  
  /// Last known position (sync access for immediate UI display)
  Position? get lastPosition => _lastPosition;
  
  /// Whether location tracking is active
  bool get isActive => _subscription != null;

  /// Call ONCE at app startup in main.dart - never again
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[LocationService] Already initialized, skipping');
      return;
    }

    // Check permissions
    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      print('[LocationService] Permission denied, cannot initialize');
      return;
    }

    _controller = StreamController<Position>.broadcast();

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters - prevents battery drain
      ),
    ).listen(
      (position) {
        _lastPosition = position;
        _controller?.add(position);
        print('[LocationService] Position update: ${position.latitude}, ${position.longitude}');
      },
      onError: (e) => print('[LocationService] Stream error: $e'),
    );

    _isInitialized = true;
    print('[LocationService] ✅ Initialized - streaming location');
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      print('[LocationService] Location services disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ===== LEGACY STATIC METHODS (for backward compatibility) =====
  // These allow existing code to keep working during migration

  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw LocationServiceException(
        'Location services are disabled. Please enable them to continue.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permission denied. Please grant permission to continue.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw LocationServiceException(
        'Location permissions are permanently denied. Please enable them from system settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final village = place.subLocality;
        final district = place.subAdministrativeArea;
        final city = place.locality;

        if (village != null && village.isNotEmpty) {
          return '$village, ${district ?? city ?? ''}';
        } else if (district != null && district.isNotEmpty) {
          return '$district, ${city ?? ''}';
        }
        return '${city ?? ''}, ${place.administrativeArea ?? ''}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Location not found';
    }
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void dispose() {
    _subscription?.cancel();
    _controller?.close();
    _isInitialized = false;
  }
}