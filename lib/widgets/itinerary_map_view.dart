import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/itinerary_model.dart';

/// Map widget showing itinerary route with all stops
class ItineraryMapView extends StatefulWidget {
  final DayItinerary itinerary;
  final Function(String stopId)? onMarkVisited;

  const ItineraryMapView({
    super.key, 
    required this.itinerary,
    this.onMarkVisited,
  });

  @override
  State<ItineraryMapView> createState() => _ItineraryMapViewState();
}

class _ItineraryMapViewState extends State<ItineraryMapView> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _followingUser = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      // Get initial position
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      // Listen for position updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });

          // Auto-center if following user
          if (_followingUser) {
            _mapController.move(
              LatLng(position.latitude, position.longitude),
              _mapController.camera.zoom,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Location tracking error: $e');
    }
  }

  void _centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
      setState(() {
        _followingUser = true;
      });
    }
  }

  Color _getSafetyColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Get all stop locations
    final stops = widget.itinerary.stops;
    if (stops.isEmpty) {
      return const Center(child: Text('No stops to display'));
    }

    // Calculate map center and bounds
    final bounds = _calculateBounds(stops);
    final center = LatLng(
      (bounds['minLat']! + bounds['maxLat']!) / 2,
      (bounds['minLng']! + bounds['maxLng']!) / 2,
    );

    // Create polyline for the route
    final routePoints = <LatLng>[];
    for (final stop in stops) {
      routePoints.add(stop.location);
    }

    // Create markers for each stop
    final markers = stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      
      return Marker(
        point: stop.location,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            _showStopDetails(context, stop, index + 1);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Marker pin
              Icon(
                Icons.location_on,
                color: index == 0 
                    ? Colors.green 
                    : index == stops.length - 1
                        ? Colors.red
                        : Colors.blue,
                size: 40,
              ),
              // Number badge
              Positioned(
                top: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            // Inner dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    // Create route segments with safety coloring
    final polylines = <Polyline>[];
    for (int i = 0; i < stops.length - 1; i++) {
      final currentStop = stops[i];
      final nextStop = stops[i + 1];
      
      // Get safety score for this segment
      final safetyScore = nextStop.routeFromPrevious?.safetyScore ?? 50.0;
      final color = _getSafetyColor(safetyScore);

      polylines.add(Polyline(
        points: [currentStop.location, nextStop.location],
        color: color,
        strokeWidth: 4.0,
      ));
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onPositionChanged: (position, hasGesture) {
                // Stop following user if they manually pan
                if (hasGesture && _followingUser) {
                  setState(() {
                    _followingUser = false;
                  });
                }
              },
            ),
            children: [
              // Base map layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tourguard.app',
              ),
              
              // Route polylines
              PolylineLayer(polylines: polylines),
              
              // Stop markers
              MarkerLayer(markers: markers),
            ],
          ),
        ),
        
        // Legend overlay
        Positioned(
          top: 10,
          right: 10,
          child: _buildLegend(),
        ),
        
        // My Location button
        if (_currentPosition != null)
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _centerOnUser,
              child: Icon(
                _followingUser ? Icons.my_location : Icons.location_searching,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  Map<String, double> _calculateBounds(List<ItineraryStop> stops) {
    double minLat = stops.first.location.latitude;
    double maxLat = stops.first.location.latitude;
    double minLng = stops.first.location.longitude;
    double maxLng = stops.first.location.longitude;

    for (final stop in stops) {
      if (stop.location.latitude < minLat) minLat = stop.location.latitude;
      if (stop.location.latitude > maxLat) maxLat = stop.location.latitude;
      if (stop.location.longitude < minLng) minLng = stop.location.longitude;
      if (stop.location.longitude > maxLng) maxLng = stop.location.longitude;
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    return {
      'minLat': minLat - latPadding,
      'maxLat': maxLat + latPadding,
      'minLng': minLng - lngPadding,
      'maxLng': maxLng + lngPadding,
    };
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Route Safety',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _legendItem(Colors.green, 'Safe (75+)'),
          _legendItem(Colors.orange, 'Caution (50-74)'),
          _legendItem(Colors.red, 'Danger (<50)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showStopDetails(BuildContext context, ItineraryStop stop, int number) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Stop number and name
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stop.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (stop.description != null) ...[
              const SizedBox(height: 12),
              Text(
                stop.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            
            if (stop.routeFromPrevious != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Route from previous stop:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip(
                    Icons.schedule,
                    stop.routeFromPrevious!.formattedDuration,
                  ),
                  const SizedBox(width: 8),
                  _infoChip(
                    Icons.straighten,
                    stop.routeFromPrevious!.formattedDistance,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSafetyColor(stop.routeFromPrevious!.safetyScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Safety: ${stop.routeFromPrevious!.safetyScore.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Mark as Visited button
            if (widget.onMarkVisited != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onMarkVisited!(stop.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Visited'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
