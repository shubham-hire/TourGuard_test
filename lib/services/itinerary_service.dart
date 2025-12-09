import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../models/itinerary_model.dart';
import '../models/safe_route_model.dart';
import 'safe_routing_service.dart';

/// Service for managing tourist itineraries with safety-aware routing
class ItineraryService {
  // Singleton pattern
  static final ItineraryService _instance = ItineraryService._internal();
  factory ItineraryService() => _instance;
  ItineraryService._internal();

  // Current itinerary being built
  DayItinerary? _currentItinerary;

  /// Get the current itinerary
  DayItinerary? get currentItinerary => _currentItinerary;

  /// Create a new itinerary
  void createItinerary({
    required String title,
    required DateTime date,
    LatLng? startLocation,
  }) {
    _currentItinerary = DayItinerary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      stops: [],
      startLocation: startLocation,
    );
  }

  /// Add a place to the itinerary
  void addStop({
    required String name,
    required LatLng location,
    required String category,
    String? description,
    DateTime? scheduledTime,
  }) {
    if (_currentItinerary == null) {
      throw Exception('No active itinerary. Call createItinerary() first.');
    }

    final stop = ItineraryStop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      category: category,
      description: description,
      scheduledTime: scheduledTime,
    );

    final updatedStops = List<ItineraryStop>.from(_currentItinerary!.stops)
      ..add(stop);

    _currentItinerary = _currentItinerary!.copyWith(stops: updatedStops);
  }

  /// Remove a stop from the itinerary
  void removeStop(String stopId) {
    if (_currentItinerary == null) return;

    final updatedStops = _currentItinerary!.stops
        .where((stop) => stop.id != stopId)
        .toList();

    _currentItinerary = _currentItinerary!.copyWith(stops: updatedStops);
  }

  /// Reorder stops in the itinerary
  void reorderStops(int oldIndex, int newIndex) {
    if (_currentItinerary == null) return;

    final stops = List<ItineraryStop>.from(_currentItinerary!.stops);
    if (newIndex > oldIndex) newIndex--;
    
    final stop = stops.removeAt(oldIndex);
    stops.insert(newIndex, stop);

    _currentItinerary = _currentItinerary!.copyWith(stops: stops);
  }

  /// Calculate safe routes between all stops
  Future<DayItinerary?> calculateRoutes() async {
    if (_currentItinerary == null || _currentItinerary!.stops.isEmpty) {
      return null;
    }

    try {
      final updatedStops = <ItineraryStop>[];
      LatLng? previousLocation = _currentItinerary!.startLocation;

      for (int i = 0; i < _currentItinerary!.stops.length; i++) {
        final stop = _currentItinerary!.stops[i];
        SafeRoute? route;

        // Calculate route from previous location to this stop
        if (previousLocation != null) {
          if (kDebugMode) {
            print('[ItineraryService] Calculating route ${i + 1}/${_currentItinerary!.stops.length}');
          }

          final routeResponse = await SafeRoutingService.calculateSafeRoute(
            origin: previousLocation,
            destination: stop.location,
          );

          route = routeResponse.recommendedRoute;
        }

        updatedStops.add(stop.copyWith(routeFromPrevious: route));
        previousLocation = stop.location;
      }

      _currentItinerary = _currentItinerary!.copyWith(stops: updatedStops);
      return _currentItinerary;
    } catch (e) {
      if (kDebugMode) {
        print('[ItineraryService] Error calculating routes: $e');
      }
      return null;
    }
  }

  /// Clear the current itinerary
  void clearItinerary() {
    _currentItinerary = null;
  }

  /// Get stop count
  int get stopCount => _currentItinerary?.stops.length ?? 0;

  /// Check if itinerary has stops
  bool get hasStops => stopCount > 0;

  /// Get recommendations for improving itinerary safety
  List<String> getRecommendations() {
    if (_currentItinerary == null) return [];

    final recommendations = <String>[];

    // Check for dangerous routes
    final dangerousCount = _currentItinerary!.dangerousRouteCount;
    if (dangerousCount > 0) {
      recommendations.add(
        'Consider taking a taxi for $dangerousCount route(s) with low safety scores'
      );
    }

    // Check overall safety
    if (_currentItinerary!.overallSafetyScore < 60) {
      recommendations.add(
        'Overall trip safety is low. Consider visiting places in a different order or at different times'
      );
    }

    // Check for high-risk zones
    final highRiskZones = _currentItinerary!.allDangerZones
        .where((zone) => zone.riskLevel == 'high')
        .toList();
    
    if (highRiskZones.isNotEmpty) {
      recommendations.add(
        'Your route crosses ${highRiskZones.length} high-risk zone(s). Plan accordingly'
      );
    }

    // Add general safety tip
    if (recommendations.isEmpty) {
      recommendations.add(
        'Your itinerary looks safe! Share it with family and stay alert'
      );
    }

    return recommendations;
  }

  /// Mark a stop as visited
  void markStopAsVisited(String stopId) {
    if (_currentItinerary == null) return;

    final updatedStops = _currentItinerary!.stops.map((stop) {
      if (stop.id == stopId) {
        return stop.copyWith(visited: true);
      }
      return stop;
    }).toList();

    _currentItinerary = _currentItinerary!.copyWith(stops: updatedStops);
  }

  /// Check if user is near any unvisited stops and mark as visited
  /// Returns the stop ID if one was auto-marked, null otherwise
  String? checkProximityAndMarkVisited(double userLat, double userLng) {
    if (_currentItinerary == null) return null;

    const double visitThresholdMeters = 50.0; // Within 50 meters = visited
    
    for (final stop in _currentItinerary!.stops) {
      if (!stop.visited) {
        final distance = _calculateDistance(
          userLat,
          userLng,
          stop.location.latitude,
          stop.location.longitude,
        );

        if (distance <= visitThresholdMeters) {
          markStopAsVisited(stop.id);
          return stop.id; // Return the ID of the auto-marked stop
        }
      }
    }

    return null;
  }

  /// Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
