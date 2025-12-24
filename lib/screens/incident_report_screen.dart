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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationAddress =
            'Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location')),
      );
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

          // Show success dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(tr('incident_reported')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text('${tr('incident_id')}: $incidentId'),
                      const SizedBox(height: 8),
                      Text(
                        tr('incident_success_message'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Use Future.microtask to avoid navigator lock
                        Future.microtask(() {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Go back to previous screen
                          }
                        });
                      },
                      child: Text(tr('ok')),
                    ),
                  ],
                );
              },
            );
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
      appBar: AppBar(
        title: Text(tr('incident_report')),
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Incident Title
              Text(
                tr('incident_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: tr('incident_title_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.info),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter incident title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Selection
              Text(
                tr('category'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedCategory = newValue);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Urgency Level
              Text(
                tr('urgency_level'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUrgency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.warning),
                ),
                items: urgencyLevels.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedUrgency = newValue);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select urgency level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                tr('description'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: tr('description_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Geo Camera Section (Compulsory)
              Text(
                'Geo Camera *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _capturedPhoto == null ? Colors.red[300]! : Colors.grey[300]!,
                    width: _capturedPhoto == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_capturedPhoto == null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Capture Geo-Tagged Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Required: Photo with location metadata',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedPhoto!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Captured',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (_photoLatitude != null && _photoLongitude != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Photo Location: ${_photoLatitude!.toStringAsFixed(6)}, ${_photoLongitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _captureGeoPhoto,
                        icon: Icon(_capturedPhoto == null ? Icons.camera_alt : Icons.camera_alt_outlined),
                        label: Text(_capturedPhoto == null ? 'Capture Photo' : 'Retake Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _capturedPhoto == null ? Colors.red[700] : Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Location
              Text(
                tr('location'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: _latitude == 0.0 && _longitude == 0.0
                          ? const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: OfflineMapWidget(
                                center: latlong.LatLng(_latitude, _longitude),
                                zoom: 15.0,
                                mapController: _flutterMapController,
                                markers: _flutterMapMarkers,
                                onTap: _onMapTap,
                                myLocationEnabled: true,
                                currentLocation: latlong.LatLng(_latitude, _longitude),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationAddress ?? 'Getting location...',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
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
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('update_location')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReport,
                  icon: const Icon(Icons.send),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(tr('submit_report')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  tr('incident_info_box'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
