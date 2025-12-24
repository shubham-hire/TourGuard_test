import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Global location provider - UI consumes this, never fetches directly.
/// Provider is PURE - just exposes the stream, no side effects.
/// Side effects (sending to WebSocket) are handled by LocationEmitter.
final locationProvider = StreamProvider<Position>((ref) {
  return LocationService().stream;
});

/// Convenience provider for last known position (sync access for immediate UI)
final lastPositionProvider = Provider<Position?>((ref) {
  return LocationService().lastPosition;
});
