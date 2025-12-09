import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/itinerary_model.dart';
import '../models/safe_route_model.dart';
import '../models/place_model.dart';
import '../services/itinerary_service.dart';
import '../services/location_service.dart';
import '../widgets/itinerary_map_view.dart';

enum ItineraryViewMode { list, map }

/// Screen for creating and viewing safe itineraries
class SafeItineraryScreen extends StatefulWidget {
  const SafeItineraryScreen({Key? key}) : super(key: key);

  @override
  State<SafeItineraryScreen> createState() => _SafeItineraryScreenState();
}

class _SafeItineraryScreenState extends State<SafeItineraryScreen> {
  final _itineraryService = ItineraryService();
  bool _isCalculating = false;
  Position? _currentPosition;
  ItineraryViewMode _viewMode = ItineraryViewMode.list;

  @override
  void initState() {
    super.initState();
    _initItinerary();
    _startLocationMonitoring();
  }

  Future<void> _initItinerary() async {
    // Get current location for start point
    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });

      // Create itinerary if doesn't exist
      if (_itineraryService.currentItinerary == null) {
        _itineraryService.createItinerary(
          title: 'My Day Trip',
          date: DateTime.now(),
          startLocation: LatLng(position.latitude, position.longitude),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // Monitor location and auto-mark visited stops
  void _startLocationMonitoring() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      setState(() {
        _currentPosition = position;
      });

      // Check if near any unvisited stops
      final markedStopId = _itineraryService.checkProximityAndMarkVisited(
        position.latitude,
        position.longitude,
      );

      if (markedStopId != null && mounted) {
        // Refresh UI
        setState(() {});
        
        // Show notification
        final stop = _itineraryService.currentItinerary?.stops
            .firstWhere((s) => s.id == markedStopId);
        
        if (stop != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('✅ Arrived at "${stop.name}"! Marked as visited.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _calculateRoutes() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      await _itineraryService.calculateRoutes();
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Routes calculated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeStop(String stopId) {
    setState(() {
      _itineraryService.removeStop(stopId);
    });
  }

  Color _getSafetyColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = _itineraryService.currentItinerary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Itinerary Planner'),
        backgroundColor: Colors.blue,
        actions: [
          if (itinerary != null && itinerary.stops.isNotEmpty) ...[
            // View mode toggle
            IconButton(
              icon: Icon(_viewMode == ItineraryViewMode.map ? Icons.list : Icons.map),
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == ItineraryViewMode.map 
                      ? ItineraryViewMode.list 
                      : ItineraryViewMode.map;
                });
              },
              tooltip: _viewMode == ItineraryViewMode.map ? 'List View' : 'Map View',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _itineraryService.clearItinerary();
                setState(() {});
                Navigator.pop(context);
              },
              tooltip: 'Clear itinerary',
            ),
          ],
        ],
      ),
      body: itinerary == null || itinerary.stops.isEmpty
          ? _buildEmptyState()
          : _buildItineraryView(itinerary),
      floatingActionButton: itinerary != null && itinerary.stops.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCalculating ? null : _calculateRoutes,
              icon: _isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.route),
              label: Text(_isCalculating ? 'Calculating...' : 'Calculate Routes'),
              backgroundColor: _isCalculating ? Colors.grey : Colors.blue,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No places added yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back to Explore and add places to your itinerary',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Browse Places'),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryView(DayItinerary itinerary) {
    final hasRoutes = itinerary.stops.any((s) => s.routeFromPrevious != null);

    return Column(
      children: [
        // Summary Card
        if (hasRoutes) _buildSummaryCard(itinerary),
        
        // View content (Map or List)
        Expanded(
          child: _viewMode == ItineraryViewMode.map
              ? _buildMapView(itinerary)
              : _buildListView(itinerary),
        ),

        // Recommendations
        if (hasRoutes) _buildRecommendations(itinerary),
      ],
    );
  }

  Widget _buildMapView(DayItinerary itinerary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ItineraryMapView(
        itinerary: itinerary,
        onMarkVisited: (stopId) {
          setState(() {
            _itineraryService.removeStop(stopId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Place marked as visited!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(DayItinerary itinerary) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itinerary.stops.length,
      itemBuilder: (context, index) {
        final stop = itinerary.stops[index];
        final isFirst = index == 0;

        return Column(
          children: [
            // Route segment (if not first)
            if (!isFirst && stop.routeFromPrevious != null)
              _buildRouteSegment(stop.routeFromPrevious!),
            
            // Stop card
            _buildStopCard(stop, index + 1),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(DayItinerary itinerary) {
    final safetyColor = _getSafetyColor(itinerary.overallSafetyScore);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: safetyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: safetyColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Safety',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${itinerary.overallSafetyScore.round()}/100',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: safetyColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: safetyColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          itinerary.safetyStatus,
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
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(itinerary.formattedTotalTime),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(itinerary.formattedTotalDistance),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSegment(SafeRoute route) {
    final safetyColor = _getSafetyColor(route.safetyScore);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: safetyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_downward, color: safetyColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: safetyColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${route.safetyScore.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.formattedDuration,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.formattedDistance,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (route.dangerZonesCrossed.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ Crosses ${route.dangerZonesCrossed.length} danger zone(s)',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(ItineraryStop stop, int number) {
    final isFirst = number == 1;
    final isLast = number == _itineraryService.currentItinerary!.stops.length;
    final isVisited = stop.visited;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isVisited
                ? Colors.grey[200]!
                : isFirst 
                    ? Colors.green[50]! 
                    : isLast 
                        ? Colors.red[50]!
                        : Colors.blue[50]!,
            isVisited ? Colors.grey[100]! : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isVisited ? 0.04 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isVisited
              ? Colors.grey[300]!
              : isFirst 
                  ? Colors.green[200]! 
                  : isLast 
                      ? Colors.red[200]!
                      : Colors.blue[200]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Number badge with gradient
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isVisited
                      ? [Colors.grey[400]!, Colors.grey[600]!]
                      : isFirst
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : isLast
                              ? [Colors.red[400]!, Colors.red[600]!]
                              : [Colors.blue[400]!, Colors.blue[600]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isVisited ? Colors.grey :  isFirst ? Colors.green : isLast ? Colors.red : Colors.blue)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (isFirst && !isVisited)
                      const Text(
                        'START',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isLast && !isVisited)
                      const Text(
                        'END',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isVisited)
                      const Text(
                        'DONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Place info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isVisited ? TextDecoration.lineThrough : null,
                      color: isVisited ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVisited ? Colors.grey[300] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stop.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      if (isFirst && !isVisited) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag, size: 12, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Starting Point',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isLast && !isVisited) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Final Stop',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isVisited) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Visited',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Action button (checkmark if visited, X if not)
            if (isVisited)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 32,
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeStop(stop.id),
                tooltip: 'Remove from itinerary',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(DayItinerary itinerary) {
    final recommendations = _itineraryService.getRecommendations();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
