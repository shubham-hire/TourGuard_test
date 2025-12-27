import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng, Marker, MarkerId, GoogleMapController;
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:flutter_map/flutter_map.dart' hide Marker;
import 'package:flutter_map/src/layer/marker_layer/marker_layer.dart' as flutter_map_markers show Marker;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:image_picker/image_picker.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/offline_map_widget.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({Key? key}) : super(key: key);

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedUrgency;
  String? _locationAddress;
  late double _latitude = 0.0;
  late double _longitude = 0.0;
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  bool _locationReady = false;
  
  // Geo camera variables
  File? _capturedPhoto;
  double? _photoLatitude;
  double? _photoLongitude;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> categories = [
    'Theft',
    'Assault',
    'Medical Emergency',
    'Accident',
    'Missing Person',
    'Suspicious Activity',
    'Other',
  ];

  final List<String> urgencyLevels = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    _flutterMapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Step 1: Try to get last known position instantly
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          _latitude = lastKnown.latitude;
          _longitude = lastKnown.longitude;
          _locationReady = true;
          _locationAddress =
              'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}';
        });
      }
      
      // Step 2: Fetch fresh position with timeout (runs in background)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // 'high' is faster than 'best'
        timeLimit: const Duration(seconds: 5), // 5 second timeout
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationReady = true;
        _locationAddress =
            'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Error getting location: $e');
      // If we already have last known position, don't show error
      if (!_locationReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location')),
        );
      }
    }
  }

  GoogleMapController? _mapController;
  MapController? _flutterMapController;
  final Set<Marker> _mapMarkers = {};
  List<flutter_map_markers.Marker> _flutterMapMarkers = [];

  void _onMapTap(TapPosition tapPosition, latlong.LatLng pos) {
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _locationAddress = 'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}';
      _mapMarkers.clear();
      _mapMarkers.add(Marker(markerId: const MarkerId('selected'), position: LatLng(_latitude, _longitude)));
      _flutterMapMarkers = [
        flutter_map_markers.Marker(
          point: pos,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
    });
  }

  Future<void> _captureGeoPhoto() async {
    try {
      // Get current location before capturing photo
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Capture photo from camera
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
          _photoLatitude = position.latitude;
          _photoLongitude = position.longitude;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    // Validate geo camera photo is captured
    if (_capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a geo-tagged photo before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final payload = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'urgency': _selectedUrgency,
          'location': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
          'address': _locationAddress,
          'photoLocation': _photoLatitude != null && _photoLongitude != null
              ? {
                  'latitude': _photoLatitude,
                  'longitude': _photoLongitude,
                }
              : null,
          'photoPath': _capturedPhoto?.path,
          'reportedAt': DateTime.now().toIso8601String(),
        };

        String incidentId = '';
        try {
          final resp = await ApiService.reportIncident(payload);
          incidentId = resp['id'] ?? resp['incidentId'] ?? '';
        } catch (e) {
          // fallback to local store when backend unreachable
          print('Backend error, saving locally: $e');
        }

        // Always save locally as backup
        final localId = await IncidentService.reportIncident(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory!,
          latitude: _latitude,
          longitude: _longitude,
        );
        if (incidentId.isEmpty) incidentId = localId;

        // SMS backup to emergency contacts if available in device
        await _sendSmsBackup(incidentId);

        if (incidentId.isNotEmpty) {
          // If High or Critical urgency, request emergency response
          if (_selectedUrgency == 'High' || _selectedUrgency == 'Critical') {
            await IncidentService.requestEmergencyResponse(
              incidentId: incidentId,
              urgencyLevel: _selectedUrgency!,
              latitude: _latitude,
              longitude: _longitude,
            );
          }

          // Show success banner from top and navigate to dashboard
          if (mounted) {
            // Use a global key to access scaffold messenger from dashboard
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            
            // Navigate to dashboard immediately
            Navigator.of(context).popUntil((route) => route.isFirst);
            
            // Show the banner after navigation (it will persist for 3 seconds)
            Future.delayed(const Duration(milliseconds: 100), () {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.green[700],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '✓ Incident Reported Successfully',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            });
          }
        }
      } catch (e) {
        print('Error submitting report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendSmsBackup(String incidentId) async {
    try {
      // Attempt to read emergency contacts from Hive box 'userBox' if present
      final box = await Hive.openBox('userBox');
      final contacts = box.get('emergencyContacts', defaultValue: []) as List<dynamic>;
      if (contacts.isEmpty) return;

      final body = Uri.encodeComponent('Incident reported: $incidentId\nTitle: ${_titleController.text}\nLocation: $_locationAddress');

      for (var c in contacts) {
        final phone = c['phone'] ?? c; // support both map or string
        final uri = Uri.parse('sms:$phone?body=$body');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      print('SMS backup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // AppBar removed as requested
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Report Incident',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing for centered title
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Subtext
                      Text(
                        'Help us keep the community safe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // DETAILS CARD
                      _buildSectionCard(
                        title: 'Incident Details',
                        icon: Icons.assignment_outlined,
                        children: [
                           _buildTextField(
                            controller: _titleController,
                            label: tr('incident_title'),
                            hint: tr('incident_title_hint'),
                            icon: Icons.title,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  value: _selectedCategory,
                                  items: categories,
                                  label: tr('category'),
                                  icon: Icons.category_outlined,
                                  onChanged: (v) => setState(() => _selectedCategory = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  value: _selectedUrgency,
                                  items: urgencyLevels,
                                  label: tr('urgency_level'),
                                  icon: Icons.warning_amber_rounded,
                                  isUrgency: true,
                                  onChanged: (v) => setState(() => _selectedUrgency = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: tr('description'),
                            hint: tr('description_hint'),
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),
                        ],
                      ),
        
                      const SizedBox(height: 20),
        
                      // EVIDENCE CARD (Geo Camera)
                      _buildSectionCard(
                        title: 'Evidence (Required)',
                        icon: Icons.camera_enhance_outlined,
                        children: [
                          GestureDetector(
                            onTap: _captureGeoPhoto,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _capturedPhoto == null ? Colors.red.withOpacity(0.5) : Colors.grey[300]!,
                                  width: 2,
                                  style: _capturedPhoto == null ? BorderStyle.solid : BorderStyle.none,
                                ),
                                image: _capturedPhoto != null
                                    ? DecorationImage(
                                        image: FileImage(_capturedPhoto!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: _capturedPhoto != null
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: _capturedPhoto == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 32,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tap to Capture Geo-Photo',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Location metadata required',
                                          style: TextStyle(
                                            color: Colors.red[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.0),
                                                Colors.black.withOpacity(0.6),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 4,
                                                )
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check, color: Colors.white, size: 14),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'Captured',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.location_on, color: Colors.white, size: 12),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${_photoLatitude?.toStringAsFixed(5)}, ${_photoLongitude?.toStringAsFixed(5)}',
                                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: _captureGeoPhoto,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
        
                      const SizedBox(height: 20),
        
                      // LOCATION CARD
                      _buildSectionCard(
                        title: 'Location',
                        icon: Icons.place_outlined,
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                 BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _locationReady 
                                ? Stack(
                                    children: [
                                      OfflineMapWidget(
                                        center: latlong.LatLng(_latitude, _longitude),
                                        zoom: 15.0,
                                        mapController: _flutterMapController,
                                        markers: _flutterMapMarkers,
                                        onTap: _onMapTap,
                                        myLocationEnabled: true,
                                        currentLocation: latlong.LatLng(_latitude, _longitude),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: FloatingActionButton.small(
                                      heroTag: 'refresh_loc',
                                      onPressed: () async {
                                        await _getCurrentLocation();
                                        if (_latitude != 0.0) {
                                          _flutterMapController?.move(latlong.LatLng(_latitude, _longitude), 15.0);
                                          _mapMarkers.clear();
                                          _mapMarkers.add(Marker(markerId: const MarkerId('selected'), position: LatLng(_latitude, _longitude)));
                                          _flutterMapMarkers = [
                                            flutter_map_markers.Marker(
                                              point: latlong.LatLng(_latitude, _longitude),
                                              width: 40,
                                              height: 40,
                                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                            ),
                                          ];
                                          setState(() {});
                                        }
                                      },
                                      backgroundColor: Colors.white,
                                      child: const Icon(Icons.my_location, color: Colors.blue),
                                    ),
                                  ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Colors.red[400],
                                            strokeWidth: 2,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Loading map...',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _locationAddress ?? 'Fetching location...',
                                  style: TextStyle(
                                     fontSize: 13, 
                                     color: Colors.grey[800],
                                     fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2, // Allow 2 lines
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
        
                      const SizedBox(height: 30),
        
                      // SUBMIT BUTTON
                      Container(
                         decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [Colors.red[700]!, Colors.red[500]!],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT REPORT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Privacy Note
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.shield_outlined, size: 14, color: Colors.green[700]),
                              ),
                              alignment: PlaceholderAlignment.middle,
                            ),
                            TextSpan(
                              text: tr('incident_info_box'),
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.red[700]),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey[500], size: 20) : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label is required';
        if (maxLines > 1 && value.length < 10) return 'Must be at least 10 chars';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    bool isUrgency = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true, 
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(
            val, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isUrgency && val == 'Critical' ? Colors.red : Colors.black87,
              fontWeight: isUrgency && val == 'Critical' ? FontWeight.bold : FontWeight.normal
            )
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down_rounded),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: isUrgency ? Colors.orange[800] : Colors.grey[500], size: 18),
        filled: true,
        fillColor: isUrgency && value == 'Critical' ? Colors.red[50] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
         border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
