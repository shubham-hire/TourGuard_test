import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show GoogleMapController, LatLng, Marker, MarkerId, Circle, CircleId, CameraPosition, CameraUpdate, BitmapDescriptor, InfoWindow;
import 'package:flutter_map/flutter_map.dart' hide Marker;
import 'package:latlong2/latlong.dart' as latlong;
import 'geofence_events_screen.dart';
import '../widgets/offline_map_widget.dart';
import '../services/offline_map_service.dart';

import '../services/active_alert_service.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import '../services/safety_score_service.dart';
import '../services/localization_service.dart';
import '../utils/constants.dart';
import '../utils/geofence_helper.dart';
import '../services/weather_service.dart';
import '../widgets/chatbot_widget.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../services/backend_service.dart';
import '../core/constants/app_colors.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const MethodChannel _notifyChannel = MethodChannel('tourapp/notifications');
  static const double _safetyRadiusKm = 3;
  StreamSubscription<Position>? _positionSub;
  // Last known position used to filter small updates
  Position? _lastProcessedPosition;
  bool _notifiedZone = false;
  // Track per-zone inside/outside state to send enter/exit notifications
  final Map<String, bool> _zoneStates = {};
  bool chatbotOpen = false;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  LatLng? _lastIncidentLocation;
  bool _isGeofencePopupVisible = false;
  List<Map<String, dynamic>> _localIncidents = [];
  Map<String, dynamic>? _safetyScoreData;
  bool _isSafetyLoading = false;
  bool _isFetchingSafety = false;
  Timer? _safetyRefreshTimer;
  DateTime? _lastSafetyUpdate;
  String? _currentAddress;
  Map<String, dynamic>? _weatherData;
  bool _isWeatherLoading = false;
  bool _isFetchingWeather = false;
  DateTime? _lastWeatherUpdate;
  Map<String, String>? _weatherAlert;
  DateTime? _lastWeatherAlertUpdate;
  List<Map<String, String>> _activeAlerts = [];
  bool _alertsLoading = false;
  bool _isFetchingAlerts = false;
  DateTime? _lastAlertUpdate;
  // Map enlarge state
  bool _isMapEnlarged = false;
  GoogleMapController? _mapController;
  MapController? _flutterMapController;
  // Civic Sense carousel assets and controller
  late final ScrollController _civicScrollController;
  int _civicIndex = 0;
  Timer? _civicAutoScrollTimer;

  // Women's Safety Data
  final List<Map<String, dynamic>> _womenSafetyTips = [
    {
      'type': 'do',
      'title': 'Stay Connected',
      'desc': 'Share live location with trusted contacts.'
    },
    {
      'type': 'do',
      'title': 'Trusted Transport',
      'desc': 'Prefer government buses or registered cabs.'
    },
    {
      'type': 'dont',
      'title': 'Avoid Isolated Areas',
      'desc': 'Especially after sunset, stick to crowded places.'
    },
    {
      'type': 'dont',
      'title': 'Don\'t Share Info',
      'desc': 'Keep travel plans private from strangers.'
    },
    {
      'type': 'do',
      'title': 'Carry Essentials',
      'desc': 'Keep power bank, pepper spray, and emergency cash.'
    },
    {
      'type': 'do',
      'title': 'Trust Instincts',
      'desc': 'If a situation feels wrong, leave immediately.'
    },
    {
      'type': 'dont',
      'title': 'Open Door at Night',
      'desc': 'Verify hotel staff ID before opening doors.'
    },
    {
      'type': 'do',
      'title': ' Dress Modestly',
      'desc': 'Respect local culture to blend in easily.'
    },
  ];

  final List<Map<String, dynamic>> _emergencyGuidance = [
    {
      'step': 1,
      'title': 'Stay Calm',
      'desc': 'Panic can cloud judgment. Take a deep breath.'
    },
    {
      'step': 2,
      'title': 'Find Safety',
      'desc': 'Move to a crowded shop, police booth, or hotel.'
    },
    {
      'step': 3,
      'title': 'Attract Attention',
      'desc': 'Scream "Help/Bachao" loudly if threatened.'
    },
    {
      'step': 4,
      'title': 'Press SOS',
      'desc': 'Use the SOS button in this app immediately.'
    },
    {
      'step': 5,
      'title': 'Dial 112',
      'desc': 'Call national emergency helpline if needed.'
    },
    {
      'step': 6,
      'title': 'Contact Embassy',
      'desc': 'For foreigners, contact your nearest embassy.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _flutterMapController = MapController();
    _initLocationAndData();
    _startGeofenceMonitor();
    _civicScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_civicTips.isEmpty) return;
      _civicAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        _civicIndex = (_civicIndex + 1) % _civicTips.length;
        final width = 260.0 + 16.0; // Card width + margin
        final offset = _civicIndex * width;
        if (_civicScrollController.hasClients) {
          _civicScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  // Monitor location and trigger notification on geofence enter
  void _startGeofenceMonitor() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      // Use best accuracy with minimal distance filter for live tracking
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Update on every movement for live tracking
        timeLimit: null, // No time limit
      ),
    ).listen(_handleLivePosition);
  }

  void _handleLivePosition(Position pos) {
    if (!mounted) return;
    
    // Update position immediately for live tracking (no movement threshold)
    _lastProcessedPosition = pos;
    
    // Update state immediately for smooth map updates - this will update the location marker
    if (mounted) {
      setState(() {
        _currentPosition = pos;
      });
    }
    
    // Evaluate geofence status (non-blocking)
    _evaluateGeofenceStatus(pos).catchError((e) => debugPrint('Geofence error: $e'));
    
    // Send location update to backend (non-blocking)
    _sendLocationToBackend(pos);
    
    // Reduce refresh frequency to avoid network bursts and main-thread work
    final shouldRefresh = _lastSafetyUpdate == null ||
        DateTime.now().difference(_lastSafetyUpdate!) >= const Duration(seconds: 60);
    if (shouldRefresh) {
      _refreshSafetyScore();
    }
    final shouldRefreshWeather = _lastWeatherUpdate == null ||
        DateTime.now().difference(_lastWeatherUpdate!) >= const Duration(minutes: 5);
    if (shouldRefreshWeather) {
      _refreshWeather();
    }
    final shouldRefreshAlerts = _lastAlertUpdate == null ||
        DateTime.now().difference(_lastAlertUpdate!) >= const Duration(minutes: 5);
    if (shouldRefreshAlerts) {
      _refreshActiveAlerts();
    }
  }

  // Send location update to backend (non-blocking)
  void _sendLocationToBackend(Position pos) async {
    try {
      final isAuthenticated = await BackendService.isAuthenticated();
      if (isAuthenticated) {
        // Send location update (fire and forget)
        BackendService.updateLocation(
          lat: pos.latitude,
          lng: pos.longitude,
        ).timeout(const Duration(seconds: 3)).catchError((error) {
          debugPrint('Backend location update error (non-critical): $error');
        });
        
        // Log activity (fire and forget)
        BackendService.logActivity(
          action: 'location_update',
          metadata: {
            'lat': pos.latitude,
            'lng': pos.longitude,
            'accuracy': pos.accuracy,
          },
        ).catchError((error) {
          debugPrint('Backend activity log error (non-critical): $error');
        });
      }
    } catch (e) {
      // Non-critical error
      debugPrint('Backend location update error: $e');
    }
  }

  Future<void> _evaluateGeofenceStatus(Position pos) async {
    for (final circle in _circles) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );
      final id = circle.circleId.value;
      final isInside = dist <= circle.radius;

      final previous = _zoneStates[id] ?? false;
      // Transition: entered
      if (isInside && !previous) {
        _zoneStates[id] = true;
        final zoneName = _zoneNameForId(id) ?? id;
        
        // Check zone type and update safety score
        String zoneType = '';
        if (zoneName.toLowerCase().contains('red') || zoneName.toLowerCase().contains('danger')) {
          zoneType = 'red';
        } else if (zoneName.toLowerCase().contains('yellow') || zoneName.toLowerCase().contains('caution')) {
          zoneType = 'yellow';
        }
        
        // Prepare notification immediately
        String notificationTitle = '⚠️ Entered Zone';
        String notificationBody = 'You entered $zoneName';
        if (zoneType == 'red' || zoneName.toLowerCase().contains('danger')) {
          notificationTitle = '🚨 Entered Danger Zone!';
          notificationBody = '⚠️ WARNING: You entered $zoneName - High risk area!';
        } else if (zoneType == 'yellow' || zoneName.toLowerCase().contains('caution') || zoneName.toLowerCase().contains('forest')) {
          notificationTitle = '⚠️ Entered Caution Zone';
          notificationBody = 'You entered $zoneName - Exercise caution';
        }
        
        // Show notification immediately (fire and forget - non-blocking)
        NotificationService.showAlertNotification(
          title: notificationTitle,
          body: notificationBody,
          type: 'geofence_enter',
        ).catchError((e) => debugPrint('Notification error: $e'));
        
        // Update safety score
        if (zoneType.isNotEmpty && _safetyScoreData != null && _safetyScoreData!['score'] is num) {
          setState(() {
            if (zoneType == 'red') {
              _safetyScoreData!['score'] = ((_safetyScoreData!['score'] as num) - 40).clamp(0, 100);
            } else if (zoneType == 'yellow') {
              _safetyScoreData!['score'] = ((_safetyScoreData!['score'] as num) - 20).clamp(0, 100);
            }
          });
        }
        
        // Log event asynchronously (non-blocking)
        _logGeofenceEvent(zoneId: id, zoneName: zoneName, event: 'enter', lat: pos.latitude, lng: pos.longitude)
            .catchError((e) => debugPrint('Log error: $e'));
        
        // Show popup notification (non-blocking)
        if (mounted) {
          _showGeofencePopup(
            title: 'Entered Zone',
            message: 'You entered $zoneName',
            isEntry: true,
          ).catchError((e) => debugPrint('Popup error: $e'));
        }
        break;
      }

      // Transition: exited
      if (!isInside && previous) {
        _zoneStates[id] = false;
        final zoneName = _zoneNameForId(id) ?? id;
        
        // Determine zone type for notification
        String zoneType = '';
        if (zoneName.toLowerCase().contains('red') || zoneName.toLowerCase().contains('danger')) {
          zoneType = 'red';
        } else if (zoneName.toLowerCase().contains('yellow') || zoneName.toLowerCase().contains('caution') || zoneName.toLowerCase().contains('forest')) {
          zoneType = 'yellow';
        }
        
        // Prepare notification immediately
        String notificationTitle = '✅ Exited Zone';
        String notificationBody = 'You exited $zoneName';
        if (zoneType == 'red' || zoneName.toLowerCase().contains('danger')) {
          notificationTitle = '✅ Exited Danger Zone';
          notificationBody = 'You safely exited $zoneName';
        } else if (zoneType == 'yellow' || zoneName.toLowerCase().contains('caution') || zoneName.toLowerCase().contains('forest')) {
          notificationTitle = '✅ Exited Caution Zone';
          notificationBody = 'You exited $zoneName';
        }
        
        // Show notification immediately (fire and forget - non-blocking)
        NotificationService.showAlertNotification(
          title: notificationTitle,
          body: notificationBody,
          type: 'geofence_exit',
        ).catchError((e) => debugPrint('Notification error: $e'));
        
        // Log event asynchronously (non-blocking)
        _logGeofenceEvent(zoneId: id, zoneName: zoneName, event: 'exit', lat: pos.latitude, lng: pos.longitude)
            .catchError((e) => debugPrint('Log error: $e'));
        
        // Show popup notification (non-blocking)
        if (mounted) {
          _showGeofencePopup(
            title: 'Exited Zone',
            message: 'You exited $zoneName',
            isEntry: false,
          ).catchError((e) => debugPrint('Popup error: $e'));
        }
        break;
      }
      // No transition: keep state as-is
      if (!_zoneStates.containsKey(id)) {
        _zoneStates[id] = isInside;
      }
    }
  }

  void _startSafetyRefreshTimer() {
    _safetyRefreshTimer?.cancel();
    _safetyRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshSafetyScore();
      _refreshWeather();
      _refreshActiveAlerts();
    });
  }

  Future<void> _refreshSafetyScore({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingSafety && !force) return;
    _isFetchingSafety = true;
    if (force || _safetyScoreData == null) {
      setState(() {
        _isSafetyLoading = true;
      });
    }
    try {
      // Debug: log that a refresh has started
      // Avoid importing foundation at top-level; using debugPrint to keep output concise
      debugPrint('[Dashboard] Refreshing safety score at position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      final address = await LocationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final incidents = await IncidentService.getNearbyIncidents(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _safetyRadiusKm,
      );
      debugPrint('[Dashboard] Nearby incidents count: ${incidents.length}');
      final data = await SafetyScoreService.getLiveSafetyScore(
        position: _currentPosition!,
        radiusKm: _safetyRadiusKm,
        incidents: incidents,
        address: address,
      );
      debugPrint('[Dashboard] Received safety score data: $data');
      if (!mounted) return;
      setState(() {
        _currentAddress = address;
        _safetyScoreData = data;
        _isSafetyLoading = false;
        _lastSafetyUpdate = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSafetyLoading = false;
      });
    } finally {
      _isFetchingSafety = false;
    }
  }

  Future<void> _refreshWeather({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingWeather && !force) return;
    _isFetchingWeather = true;
    if (force || _weatherData == null) {
      setState(() {
        _isWeatherLoading = true;
      });
    }
    try {
      // Try OpenWeatherMap first (uses provided API key). Fall back to existing PirateWeather fetch.
      Map<String, dynamic>? data;
      final odata = await WeatherService.fetchOpenWeatherCurrent(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      if (odata != null) {
        data = {
          'summary': (odata['description'] ?? '').toString(),
          'temperature': (odata['temp'] as double?) ?? 0.0,
          'apparentTemperature': (odata['temp'] as double?) ?? 0.0,
          'humidity': (odata['humidity'] as double?) ?? 0.0,
          'precipProbability': (odata['precipProbability'] as double?) ?? 0.0,
          'windSpeed': (odata['windSpeed'] as double?) ?? 0.0,
          'icon': odata['icon'],
          'timestamp': DateTime.now(),
        };
      } else {
        data = await WeatherService.fetchCurrentWeather(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }
      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _isWeatherLoading = false;
        _lastWeatherUpdate = DateTime.now();
        _updateWeatherAlert(data!);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isWeatherLoading = false;
      });
    } finally {
      _isFetchingWeather = false;
    }
  }

  void _updateWeatherAlert(Map<String, dynamic> weatherData) {
    final summary = (weatherData['summary'] as String?) ?? 'Weather update';
    final temp = (weatherData['temperature'] as double?) ?? 0;
    final precip = (weatherData['precipProbability'] as double?) ?? 0;
    final wind = (weatherData['windSpeed'] as double?) ?? 0;
    final severity = precip >= 0.6
        ? 'danger'
        : precip >= 0.3 || wind >= 40
            ? 'caution'
            : 'safe';
    final message =
        '${temp.toStringAsFixed(1)}°C · $summary · Rain ${(precip * 100).round()}%';
    _weatherAlert = {
      'title': 'Weather Update',
      'badge': 'Info',
      'severity': severity,
      'message': message,
    };
    _lastWeatherAlertUpdate = DateTime.now();
  }

  Future<void> _refreshActiveAlerts({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingAlerts && !force) return;
    if (_localIncidents.isEmpty && _activeAlerts.isNotEmpty && !force) return;
    _isFetchingAlerts = true;
    if (force || _activeAlerts.isEmpty) {
      setState(() {
        _alertsLoading = true;
      });
    }
    try {
      final alerts = await ActiveAlertService.generateAlerts(
        position: _currentPosition!,
        incidents: _localIncidents,
        weatherData: _weatherData,
      );
      if (!mounted) return;
      setState(() {
        _activeAlerts = alerts;
        _alertsLoading = false;
        _lastAlertUpdate = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alertsLoading = false;
      });
    } finally {
      _isFetchingAlerts = false;
    }
  }

  Future<void> _showSystemNotification(String title, String body) async {
    try {
      await _notifyChannel.invokeMethod('showNotification', {'title': title, 'body': body});
    } catch (_) {}
  }
  @override
  void dispose() {
    _positionSub?.cancel();
    _safetyRefreshTimer?.cancel();
    _civicAutoScrollTimer?.cancel();
    _civicScrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndData() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = pos;
      });
      await _refreshSafetyScore(force: true);
      await _refreshWeather(force: true);
      _startSafetyRefreshTimer();

      // Load incidents from local storage to show markers
      final incidents = await IncidentService.getAllIncidents();
      for (var inc in incidents) {
        if (inc['location'] != null) {
          final lat = (inc['location']['latitude'] as num).toDouble();
          final lng = (inc['location']['longitude'] as num).toDouble();
          _markers.add(Marker(
            markerId: MarkerId(inc['id'] ?? DateTime.now().toIso8601String()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: inc['title'] ?? 'Incident', snippet: inc['category']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
          // Store last incident location for geofence
          _lastIncidentLocation = LatLng(lat, lng);
        }
      }
      // Add blue geofence circle if last incident exists
      if (_lastIncidentLocation != null) {
        _circles.add(
          Circle(
            circleId: const CircleId('incident_geofence'),
            center: _lastIncidentLocation!,
            radius: 50,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
      setState(() {
        _localIncidents = incidents;
      });
      await _refreshActiveAlerts(force: true);

      // Predefined geofence circles
      // Use helper to build fixed circles from constants
      _circles.addAll(GeofenceHelper.buildFixedCircles());
      setState(() {});
      // Initialize per-zone state based on current position (no notifications)
      if (_currentPosition != null && _circles.isNotEmpty) {
        for (final circle in _circles) {
          final dist = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            circle.center.latitude,
            circle.center.longitude,
          );
          _zoneStates[circle.circleId.value] = dist <= circle.radius;
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildDashboard(context);
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    // Get values
    final zoneStatus = _zoneStatusLabel();
    final timeLabel = _timeLabel();
    final crowdDensity = _crowdDensityLabel();
    final weatherLabel = _weatherLabel();
    final scoreValue = _formatScoreValue();

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite, 
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopHeader(context),
                  const SizedBox(height: 24),
                  _buildSafetyScoreCard(scoreValue, zoneStatus, timeLabel, crowdDensity, weatherLabel),
                  const SizedBox(height: 24),
                  _buildCreativeHeader('Live Location', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _buildMapSection(context),
                  const SizedBox(height: 24),
                  // Active Alerts Section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(2), // Border width
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCreativeHeader('Active Alerts', Icons.warning_amber_rounded, fontSize: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (_activeAlerts.length + (_weatherAlert != null ? 1 : 0)).toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_alertsLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_activeAlerts.isEmpty && _weatherAlert == null)
                            const Padding(
                               padding: EdgeInsets.all(8.0),
                               child: Text('No active alerts at this time.', style: TextStyle(color: AppColors.textLight)),
                            )
                          else
                            Column(
                              children: [
                                ..._activeAlerts.map(
                                  (alert) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildAlert(
                                      alert['title'] ?? 'Alert',
                                      alert['badge'] ?? 'Info',
                                      _alertColor(alert['severity'] ?? 'caution'),
                                      alert['message'] ?? 'Details unavailable.',
                                      alert['timeAgo'] ?? 'moments ago',
                                    ),
                                  ),
                                ),
                                if (_weatherAlert != null)
                                  _buildAlert(
                                    _weatherAlert!['title'] ?? 'Weather Update',
                                    _weatherAlert!['badge'] ?? 'Info',
                                    _alertColor(_weatherAlert!['severity'] ?? 'caution'),
                                    _weatherAlert!['message'] ?? 'Latest weather data unavailable.',
                                    _weatherAlert!['timeAgo'] ??
                                        _formatTimeAgo(_lastWeatherAlertUpdate),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ), // Closing Active Alerts Container
                  const SizedBox(height: 24),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       _buildCreativeHeader('Essentials', Icons.stars_rounded),
                       Text('Explore More', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                     ]
                  ),
                  const SizedBox(height: 12),
                  _buildFeaturesGrid(context),
                  const SizedBox(height: 24),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       _buildCreativeHeader('Coming Soon', Icons.rocket_launch_outlined),
                       Text('Future Updates', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                     ]
                  ),
                  const SizedBox(height: 12),
                  _buildFutureFeaturesCarousel(context),
                  // Civic Sense Moved to Essentials Grid
                  const SizedBox(height: 100), // Extra space at bottom
                ],
              ),
            ),
            // Chatbot Button
          //   Positioned(
          //     bottom: 110, // Adjusted for floating nav bar
          //     right: 16,
          //     child: FloatingActionButton(
          //       heroTag: 'chatbot',
          //       backgroundColor: AppColors.navyBlue,
          //       onPressed: () {
          //         setState(() {
          //           chatbotOpen = !chatbotOpen;
          //         });
          //       },
          //       child: Stack(
          //         clipBehavior: Clip.none,
          //         children: [
          //           const Icon(Icons.smart_toy_outlined, color: Colors.white),
          //           Positioned(
          //             top: -12,
          //             right: -12,
          //             child: Container(
          //               padding: const EdgeInsets.all(4),
          //               decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          //               child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          //   if (chatbotOpen)
          //     ChatbotWidget(
          //       onClose: () {
          //         setState(() {
          //           chatbotOpen = false;
          //         });
          //       },
          //     ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativeHeader(String title, IconData icon, {double fontSize = 18}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.saffron.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.saffron, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.navyBlue,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  final user = auth.user;
                  final name = user?.name ?? 'Guest';
                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navyBlue, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.navyBlue,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back,',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              onPressed: () {
                 Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GeofenceEventsScreen()));
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 28, color: AppColors.textDark),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyScoreCard(String score, String zone, String time, String crowd, String weather) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(2), // Border width
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Tourist Safety Score',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              score,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppColors.indiaGreen),
            ),
            Text(
              zone,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.indiaGreen),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreMetric(Icons.shield_outlined, zone, 'Zone'),
                _buildScoreMetric(Icons.access_time, time, 'Time'),
                _buildScoreMetric(Icons.groups_outlined, crowd, 'Crowd'),
                _buildScoreMetric(Icons.wb_sunny_outlined, weather.split('·').first.trim(), 'Weather'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.saffron, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(2), // Gradient border width
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
             _currentPosition == null
                 ? const Center(child: CircularProgressIndicator())
                 : OfflineMapWidget(
                      center: latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 14.0,
                      mapController: _flutterMapController,
                      markers: MapMarkerConverter.convertGoogleMarkersToFlutterMap(_markers),
                      circles: MapCircleConverter.convertGoogleCirclesToFlutterMap(_circles),
                      myLocationEnabled: true,
                      currentLocation: latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                   ),
             Positioned(
               bottom: 12,
               right: 12,
               child: FloatingActionButton.small(
                 heroTag: 'recenter',
                 backgroundColor: AppColors.surfaceWhite,
                 child: const Icon(Icons.my_location, color: AppColors.navyBlue),
                 onPressed: () {
                    if (_currentPosition != null && _flutterMapController != null) {
                       _flutterMapController!.move(latlong.LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0);
                    }
                 },
               ),
             ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _futureFeatures = [
    {
      'title': 'AR Navigation',
      'icon': Icons.view_in_ar,
      'desc': 'Navigate with Augmented Reality overlays.'
    },
    {
      'title': 'Voice Guide',
      'icon': Icons.record_voice_over,
      'desc': 'Listen to stories about landmarks near you.'
    },
    {
      'title': 'Smart Itinerary',
      'icon': Icons.auto_awesome,
      'desc': 'AI-generated plans based on your interests.'
    },
    {
      'title': 'Offline Mode',
      'icon': Icons.cloud_off,
      'desc': 'Access maps and guides without internet.'
    },
  ];

  Widget _buildFutureFeaturesCarousel(BuildContext context) {
     return SizedBox(
       height: 120,
       child: ListView.builder(
         scrollDirection: Axis.horizontal,
         itemCount: _futureFeatures.length,
         itemBuilder: (context, index) {
            final feature = _futureFeatures[index];
            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 16, bottom: 8, top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                gradient: LinearGradient(
                  colors: [Colors.white, AppColors.saffron.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.navyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(feature['icon'] as IconData, color: AppColors.navyBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                             feature['title'] as String,
                             style: const TextStyle(
                               color: AppColors.navyBlue,
                               fontWeight: FontWeight.bold,
                               fontSize: 14,
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                       feature['desc'] as String,
                       style: TextStyle(
                         color: AppColors.textDark.withOpacity(0.6),
                         fontSize: 11,
                         height: 1.3,
                       ),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
         },
       ),
     );
  }

  final List<Map<String, dynamic>> _civicTips = [
    {
      'title': 'Keep It Clean',
      'text': 'Always use dustbins. Help us keep our tourist spots pristine and beautiful for everyone.',
      'icon': Icons.delete_outline_rounded,
      'color': Colors.green,
    },
    {
      'title': 'Respect Heritage',
      'text': 'Preserve our history. Please do not scribble on monuments or touch artifacts.',
      'icon': Icons.account_balance_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Eco-Friendly',
      'text': 'Avoid single-use plastics. Carry a reusable water bottle and bag.',
      'icon': Icons.eco_outlined,
      'color': Colors.teal,
    },
    {
      'title': 'Queue Culture',
      'text': 'Respect queues at ticket counters and attractions. Patience makes the experience better.',
      'icon': Icons.people_outline_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'No Spitting',
      'text': 'Spitting in public places is an offence and spoils the beauty of our country.',
      'icon': Icons.block_flipped,
      'color': Colors.redAccent,
    },
  ];

  final List<Map<String, dynamic>> _culturalEthicsData = [
    {
      'title': 'Religious Places',
      'icon': Icons.temple_hindu_rounded,
      'color': Colors.orange,
      'points': [
        'Always remove shoes where required.',
        'Dress modestly (cover shoulders/knees).',
        'Avoid loud behavior.',
      ]
    },
    {
      'title': 'Photography Rules',
      'icon': Icons.camera_alt_rounded,
      'color': Colors.blue,
      'points': [
        'Ask permission before photographing people.',
        'No photos in military/govt zones.',
      ]
    },
    {
      'title': 'Public Behavior',
      'icon': Icons.emoji_people_rounded,
      'color': Colors.pink,
      'points': [
        'Avoid PDA in conservative areas.',
        'No littering or spitting.',
      ]
    },
    {
      'title': 'Local Customs',
      'icon': Icons.handshake_rounded,
      'color': Colors.teal,
      'points': [
        'Use right hand for eating/giving.',
        'Learn basic greetings (Namaste).',
        'Check tipping norms.',
      ]
    },
    {
      'title': 'Legal Boundaries',
      'icon': Icons.gavel_rounded,
      'color': Colors.red,
      'points': [
        'Strict drug/alcohol laws in some areas.',
        'Traffic rules: Helmet/Seatbelt mandatory.',
        'Carry ID proof at all times.',
      ]
    },
    {
      'title': 'Cultural Sensitivity',
      'icon': Icons.favorite_rounded,
      'color': Colors.purple,
      'points': [
        'Avoid political/offensive topics.',
        'Respect festivals and rituals.',
        'Keep noise low in quiet areas.',
      ]
    },

  ];

  final List<Map<String, dynamic>> _moneyMattersData = [
    {
      'title': 'Currency & Payments',
      'icon': Icons.currency_rupee_rounded,
      'color': Colors.blueGrey,
      'gradient': [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
      'points': [
         'Always carry small notes.',
         'Prefer digital wallets in cities.',
         'Check exchange rates officially.',
      ]
    },
    {
      'title': 'ATMs & Banks',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.indigo,
      'gradient': [Color(0xFF141E30), Color(0xFF243B55)],
      'points': [
        'Use ATMs in malls/banks only.',
        'Inform bank before traveling abroad.',
      ]
    },
    {
      'title': 'Tourist Scams',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.redAccent,
      'gradient': [Color(0xFF8E0E00), Color(0xFF1F1C18)],
      'points': [
        'Confirm prices before purchase.',
        'Beware of fake guides/drivers.',
        'Watch out for hidden fees.',
      ]
    },
    {
      'title': 'Tips for Safety',
      'icon': Icons.lock_outline_rounded,
      'color': Colors.green,
      'gradient': [Color(0xFF134E5E), Color(0xFF71B280)],
      'points': [
        'Don\'t share PINs.',
        'Keep card photocopies separate.',
        'Avoid flashing expensive gadgets.',
      ]
    },
  ];

  Widget _buildFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1, // Slightly wider cards
      children: [
        // Women's Safety Card
        _buildFeatureCard(
          title: "Women's Safety",
          icon: Icons.shield_moon_rounded,
          color: Colors.pinkAccent,
          subtitle: 'Tips & Help',
          onTap: () => _showWomenSafetyDialog(context),
        ),
        // Civic Sense Card
        _buildFeatureCard(
          title: 'Civic Sense',
          icon: Icons.volunteer_activism_rounded,
          color: AppColors.indiaGreen,
          subtitle: 'Be Responsible',
          onTap: () {
             _showCivicSenseDialog(context);
          },
        ),
        // Cultural Ethics Card
        _buildFeatureCard(
          title: 'Cultural Ethics',
          icon: Icons.diversity_3_rounded,
          color: Colors.deepPurpleAccent,
          subtitle: 'Local Etiquette',
          onTap: () => _showCulturalEthicsDialog(context),
        ),
        // Money Matters Card
        _buildFeatureCard(
          title: 'Money Matters',
          icon: Icons.wallet_travel_rounded,
          color: Colors.blueGrey,
          subtitle: 'Financial Safety',
          onTap: () => _showMoneyMattersDialog(context),
        ),
      ],
    );
  }

  void _showMoneyMattersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 600, // Fixed height for Wallet look
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
               // Header
               Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.blueGrey[50],
                            shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wallet_travel_rounded, color: Colors.blueGrey, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Money Matters",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Swipe for Financial Cards",
                              style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
               ),
               
               // Wallet Carousel
               Expanded(
                 child: PageView.builder(
                   controller: PageController(viewportFraction: 0.85),
                   itemCount: _moneyMattersData.length,
                   padEnds: true,
                   itemBuilder: (context, index) {
                     final card = _moneyMattersData[index];
                     return Container(
                       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(24),
                         gradient: LinearGradient(
                           colors: card['gradient'] as List<Color>,
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         boxShadow: [
                           BoxShadow(color: (card['gradient'] as List<Color>)[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10)),
                         ],
                       ),
                       child: Stack(
                         children: [
                            // Card Chip
                            Positioned(
                              top: 30,
                              left: 30,
                              child: Icon(Icons.sim_card_rounded, color: Colors.white.withOpacity(0.8), size: 40),
                            ),
                            // Bank Icon / Title
                            Positioned(
                              top: 30,
                              right: 30,
                              child: Icon(card['icon'] as IconData, color: Colors.white, size: 40),
                            ),
                            
                            // Card Content
                            Positioned(
                              top: 90,
                              left: 30,
                              right: 30,
                              bottom: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: ListView(
                                       physics: const NeverScrollableScrollPhysics(),
                                       children: (card['points'] as List<String>).map((point) => Padding(
                                         padding: const EdgeInsets.only(bottom: 12),
                                         child: Row(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             const Padding(
                                               padding: EdgeInsets.only(top: 4),
                                               child: Icon(Icons.check_circle, color: Colors.white70, size: 16),
                                             ),
                                             const SizedBox(width: 12),
                                             Expanded(
                                               child: Text(
                                                 point,
                                                 style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                                               ),
                                             ),
                                           ],
                                         ),
                                       )).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Footer decoration
                            Positioned(
                              bottom: 20,
                              right: 30,
                              child: Text(
                                "TOURGUARD SECURE",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                         ],
                       ),
                     );
                   },
                 ),
               ),
               const SizedBox(height: 30),
            ],
          ),
        );
      }
    );
  }

  void _showCulturalEthicsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                   // Header
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple.withOpacity(0.1), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.diversity_3_rounded, color: Colors.deepPurpleAccent, size: 32),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cultural Ethics",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Respect & Connect",
                                  style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                   ),
                   
                   // Accordion List
                   Expanded(
                     child: ListView.builder(
                       controller: scrollController,
                       padding: const EdgeInsets.all(20),
                       itemCount: _culturalEthicsData.length,
                       itemBuilder: (context, index) {
                         final item = _culturalEthicsData[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.grey.withOpacity(0.2)),
                             boxShadow: [
                               BoxShadow(color: (item['color'] as Color).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                             ],
                           ),
                           child: Theme(
                             data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                             child: ExpansionTile(
                               leading: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: (item['color'] as Color).withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                               ),
                               title: Text(
                                 item['title'] as String,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                               ),
                               childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                               expandedCrossAxisAlignment: CrossAxisAlignment.start,
                               children: (item['points'] as List<String>).map((point) {
                                 return Padding(
                                   padding: const EdgeInsets.only(bottom: 8),
                                   child: Row(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Icon(Icons.arrow_right_rounded, size: 20, color: (item['color'] as Color).withOpacity(0.7)),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: Text(
                                           point,
                                           style: TextStyle(color: Colors.grey[700], height: 1.4),
                                         ),
                                       ),
                                     ],
                                   ),
                                 );
                               }).toList(),
                             ),
                           ),
                         );
                       },
                     ),
                   ),
                ],
              );
            }
          ),
        );
      }
    );
  }

  void _showCivicSenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                   // Creative Header
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.saffron.withOpacity(0.1), Colors.white, AppColors.indiaGreen.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.indiaGreen, size: 32),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Civic Sense",
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Our Duty, Our Pride",
                                  style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 20)
                            ),
                            onPressed: () => Navigator.pop(context)
                          ),
                        ],
                      ),
                   ),
                   
                   // List of Tips
                   Expanded(
                     child: ListView.builder(
                       controller: scrollController,
                       padding: const EdgeInsets.all(20),
                       itemCount: _civicTips.length,
                       itemBuilder: (context, index) {
                         final tip = _civicTips[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 20),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(20),
                             boxShadow: [
                               BoxShadow(
                                 color: (tip['color'] as Color).withOpacity(0.1),
                                 blurRadius: 15,
                                 offset: const Offset(0, 5),
                               ),
                             ],
                             border: Border.all(color: (tip['color'] as Color).withOpacity(0.2)),
                           ),
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(20),
                             child: Stack(
                               children: [
                                 // Background Decor
                                 Positioned(
                                   right: -10,
                                   top: -10,
                                   child: Icon(
                                      tip['icon'] as IconData,
                                      size: 80,
                                      color: ((tip['color'] as Color?) ?? Colors.grey).withOpacity(0.05),
                                   ),
                                 ),
                                 Padding(
                                   padding: const EdgeInsets.all(20),
                                   child: Row(
                                     children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: ((tip['color'] as Color?) ?? Colors.grey).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon((tip['icon'] as IconData?) ?? Icons.info, color: (tip['color'] as Color?) ?? Colors.grey, size: 28),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tip['title'] as String,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey[900],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                tip['text'] as String,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blueGrey[700],
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         );
                       },
                     ),
                   ),
                ],
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navyBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWomenSafetyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[50]!, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.shield_moon_rounded, color: Colors.pinkAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                     const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Women's Safety Guide",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Travel Safe, Travel Free",
                            style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicator: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab, // Ensure full width
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Safety Tips"),
                    Tab(text: "Emergency Guide"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  children: [
                    // Creative Safety Tips Tab
                    ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _womenSafetyTips.length,
                      itemBuilder: (context, index) {
                        final tip = _womenSafetyTips[index];
                        final isDo = tip['type'] == 'do';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isDo ? Colors.green : Colors.red).withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Decorative background icon (faded)
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  isDo ? Icons.check_circle_outline : Icons.highlight_off,
                                  size: 100,
                                  color: (isDo ? Colors.green : Colors.red).withOpacity(0.05),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDo ? Colors.green[50] : Colors.red[50], // Soft background
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        isDo ? Icons.check_rounded : Icons.close_rounded,
                                        color: isDo ? Colors.green[700] : Colors.red[700],
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isDo ? 'DO' : "DON'T",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isDo ? Colors.green[800] : Colors.red[800],
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            tip['title'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: AppColors.navyBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            tip['desc'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Left Accent Bar
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 4,
                                child: Container(color: isDo ? Colors.green : Colors.redAccent),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    // Timeline Emergency Tab
                    ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(24),
                      itemCount: _emergencyGuidance.length,
                      itemBuilder: (context, index) {
                        final step = _emergencyGuidance[index];
                        final isLast = index == _emergencyGuidance.length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline logic
                            Column(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.navyBlue, Colors.blueAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${step['step']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 50, // Connector height
                                    color: Colors.grey[300],
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24), // Spacing for next item
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.navyBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step['desc'],
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCivicSenseCarousel(BuildContext context) {
     return SizedBox(
       height: 140,
       child: ListView.builder(
         scrollDirection: Axis.horizontal,
         itemCount: _civicTips.length,
         itemBuilder: (context, index) {
            final tip = _civicTips[index];
            return Container(
              width: 260,
              margin: const EdgeInsets.only(right: 16, bottom: 8, top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                border: Border.all(color: AppColors.saffron.withOpacity(0.8), width: 1),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                   // Watermark Background
                   Positioned.fill(
                      child: Center(
                        child: Opacity(
                          opacity: 0.2
                          ,
                          child: Image.asset(
                            'assets/images/ashoka_emblem.jpg',
                            height: 140,
                            width: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                   ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                           tip['title']!,
                           style: const TextStyle(
                             color: AppColors.navyBlue,
                             fontWeight: FontWeight.bold,
                             fontSize: 16,
                           ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                           tip['text']!,
                           style: TextStyle(
                             color: AppColors.textDark.withOpacity(0.8),
                             fontSize: 12,
                             height: 1.4,
                           ),
                           maxLines: 3,
                           overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
         },
       ),
     );
  }

  String _formatScoreValue() {
    final value = _safetyScoreData?['score'];
    if (value is num) {
      final clamped = value.clamp(0, 100);
      return clamped.round().toString();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return _isSafetyLoading ? '—' : '--';
  }

  String _zoneStatusLabel() {
    final value = _safetyScoreData?['zoneStatus'];
    if (value is String && value.trim().isNotEmpty) {
      return value.toUpperCase();
    }
    return _isSafetyLoading ? 'Updating...' : 'Unknown';
  }

  String _timeLabel() {
    final value = _safetyScoreData?['time'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (_lastSafetyUpdate != null) {
      return _formatTime(_lastSafetyUpdate!);
    }
    return _isSafetyLoading ? 'Updating...' : '--:--';
  }

  String _crowdDensityLabel() {
    final value = _safetyScoreData?['crowdDensity'];
    if (value is String && value.trim().isNotEmpty) {
      return value.toUpperCase();
    }
    return _isSafetyLoading ? 'Calculating...' : 'Unknown';
  }

  String _weatherLabel() {
    if (_weatherData != null) {
      final temp = (_weatherData?['temperature'] as double?) ?? 0;
      final summary = (_weatherData?['summary'] as String?) ?? 'Unknown';
      final tempLabel = temp == 0 ? '--' : temp.toStringAsFixed(1);
      return '$tempLabel°C · $summary';
    }
    final value = _safetyScoreData?['weather'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return _isWeatherLoading ? 'Detecting...' : 'Unknown';
  }

  Color _zoneStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return Colors.green;
      case 'CAUTION':
        return Colors.orange;
      case 'DANGER':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _crowdDensityColor(String density) {
    switch (density.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _alertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'danger':
        return Colors.red;
      case 'caution':
        return Colors.orange;
      case 'safe':
        return Colors.green;
      case 'security':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatTime(DateTime time) {
    final hours = _twoDigit(time.hour);
    final minutes = _twoDigit(time.minute);
    return '$hours:$minutes';
  }

  String _twoDigit(int value) => value.toString().padLeft(2, '0');

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'moments ago';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  String? _zoneNameForId(String id) {
    try {
      final zones = AppConstants.geofenceZones;
      for (final z in zones) {
        if ((z['id'] as String) == id) return (z['name'] as String?) ?? id;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _logGeofenceEvent({required String zoneId, required String zoneName, required String event, required double lat, required double lng}) async {
    try {
      const boxName = 'geofence_events';
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      final id = 'GE-${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'id': id,
        'zoneId': zoneId,
        'zoneName': zoneName,
        'event': event,
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await box.put(id, payload);
      debugPrint('[Geofence] Logged event: $payload');
    } catch (e) {
      debugPrint('[Geofence] Failed to log event: $e');
    }
  }

  Widget _buildSafetyItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyZone(String name, String distance, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String title, String badge, Color badgeColor, String message, String time) {
    final isSecurity = badge.toLowerCase().contains('security') || title.toLowerCase().contains('security');
    final color = isSecurity ? Colors.blue : badgeColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        elevation: 3,
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            width: 44,
            child: Icon(
              icon,
              color: Colors.blue[800],
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTurnByTurnNavigation(BuildContext context) async {
    if (_currentPosition == null) {
      _showMapMessage(context, tr('location_unavailable'));
      return;
    }
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final nativeUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webFallback = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    final launchedNative = await _tryLaunchUri(nativeUri);
    if (launchedNative) return;

    final launchedWeb = await _tryLaunchUri(webFallback);
    if (!launchedWeb && mounted) {
      _showMapMessage(context, tr('navigation_launch_failed'));
    }
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    if (_currentPosition == null) {
      _showMapMessage(context, tr('location_unavailable'));
      return;
    }
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webFallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final launchedGeo = await _tryLaunchUri(geoUri);
    if (launchedGeo) return;

    final launchedWeb = await _tryLaunchUri(webFallback);
    if (!launchedWeb && mounted) {
      _showMapMessage(context, tr('maps_launch_failed'));
    }
  }

  Future<bool> _tryLaunchUri(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  void _showMapMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showDownloadMapDialog(BuildContext context) async {
    if (_currentPosition == null) {
      _showMapMessage(context, tr('location_unavailable'));
      return;
    }

    double selectedRadius = 5.0; // Default 5km radius
    bool isDownloading = false;
    int downloadedTiles = 0;
    int totalTiles = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Download Maps for Offline Use'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select the area radius to download. Larger areas will take more time and storage space.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text('Radius: ${selectedRadius.toStringAsFixed(1)} km'),
              Slider(
                value: selectedRadius,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: '${selectedRadius.toStringAsFixed(1)} km',
                onChanged: isDownloading
                    ? null
                    : (value) {
                        setDialogState(() {
                          selectedRadius = value;
                        });
                      },
              ),
              if (isDownloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalTiles > 0 ? downloadedTiles / totalTiles : 0,
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloading: $downloadedTiles / $totalTiles tiles',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            if (!isDownloading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            if (!isDownloading)
              ElevatedButton(
                onPressed: () async {
                  setDialogState(() {
                    isDownloading = true;
                  });

                  try {
                    await OfflineMapService.preDownloadRegion(
                      center: latlong.LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      radiusKm: selectedRadius,
                      onProgress: (downloaded, total) {
                        if (mounted) {
                          setDialogState(() {
                            downloadedTiles = downloaded;
                            totalTiles = total;
                          });
                        }
                      },
                    );

                    if (mounted) {
                      Navigator.of(context).pop();
                      _showMapMessage(
                        context,
                        'Maps downloaded successfully! You can now view them offline.',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      _showMapMessage(
                        context,
                        'Error downloading maps: ${e.toString()}',
                      );
                    }
                  }
                },
                child: const Text('Download'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGeofencePopup({
    required String title,
    required String message,
    bool isEntry = true,
  }) async {
    if (!mounted || _isGeofencePopupVisible) return;
    
    _isGeofencePopupVisible = true;
    
    if (!mounted) {
      _isGeofencePopupVisible = false;
      return;
    }
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isEntry ? Icons.location_on : Icons.location_off,
              color: isEntry ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _isGeofencePopupVisible = false;
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    _isGeofencePopupVisible = false;
  }
}
