import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

/// LocationEmitter bridges LocationService → WebSocket/Backend
/// Keeps providers PURE (no side effects in Riverpod providers)
/// 
/// Call start() ONCE at app launch. It will:
/// 1. Listen to LocationService stream
/// 2. Throttle updates (max 1 per 10 seconds)
/// 3. Send to WebSocket when available (Phase 4)
class LocationEmitter {
  static final LocationEmitter _instance = LocationEmitter._internal();
  factory LocationEmitter() => _instance;
  LocationEmitter._internal();

  StreamSubscription<Position>? _subscription;
  DateTime? _lastEmitTime;
  static const _minEmitInterval = Duration(seconds: 10);
  bool _started = false;

  /// Start listening and emitting - call ONCE at app startup
  void start() {
    if (_started) {
      print('[LocationEmitter] Already started, skipping');
      return;
    }

    final locationService = LocationService();

    _subscription = locationService.stream.listen((position) {
      // Client-side rate limiting (10 second minimum interval)
      final now = DateTime.now();
      if (_lastEmitTime != null && now.difference(_lastEmitTime!) < _minEmitInterval) {
        return; // Throttled - skip this update
      }
      _lastEmitTime = now;

      // TODO Phase 4: Wire up WebSocket here
      // For now, just log that we would send
      print('[LocationEmitter] Would send: ${position.latitude}, ${position.longitude}');
    });

    _started = true;
    print('[LocationEmitter] ✅ Started - listening to location stream');
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
