import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'incident_report_screen.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../services/api_environment.dart';
import '../services/backend_service.dart';
import '../core/constants/app_colors.dart';
import '../services/gemini_service.dart';
import '../services/websocket_service.dart';

class EmergencyScreen extends StatefulWidget {
  final bool autoTrigger;
  const EmergencyScreen({super.key, this.autoTrigger = false});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _sosPressed = false;
  late final stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListeningForHelp = false;
  DateTime? _lastVoiceTrigger;

  // Map related
  GoogleMapController? _mapController;
  LatLng? _incidentLocation;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initVoiceRecognition();
    
    if (widget.autoTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Auto-start SOS logic with countdown
        if (mounted) {
          _handleAutoSOS();
        }
      });
    }
  }

  void _handleAutoSOS() {
    bool cancelled = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚨 Widget Triggered! Sending SOS in 5s...'),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'CANCEL',
          textColor: Colors.white,
          onPressed: () {
            cancelled = true;
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('SOS Cancelled'), backgroundColor: Colors.green),
            );
          },
        ),
      ),
    ).closed.then((_) {
      if (!cancelled && mounted) {
        _handleVoiceTriggeredSOS();
      }
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _initVoiceRecognition() async {
    try {
      final hasSpeech = await _speechToText.initialize(
        onError: (errorNotification) => _handleSpeechError(errorNotification.errorMsg),
        onStatus: _handleSpeechStatus,
      );
      if (!mounted) return;
      setState(() {
        _speechEnabled = hasSpeech;
      });
      if (hasSpeech) {
        _startListeningForHelp();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  Future<void> _startListeningForHelp() async {
    if (!_speechEnabled || _isListeningForHelp) return;
    await _speechToText.listen(
      onResult: _handleSpeechResult,
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isListeningForHelp = _speechToText.isListening;
    });
  }



  void _handleSpeechResult(SpeechRecognitionResult result) {
    try {
      final recognized = result.recognizedWords.trim().toLowerCase();
      if (recognized.isEmpty) return;

      final now = DateTime.now();
      final recentlyTriggered = _lastVoiceTrigger != null &&
          now.difference(_lastVoiceTrigger!) < const Duration(seconds: 4);
      
      if (recentlyTriggered) return;

      print('[Voice] Recognized: "$recognized" | confidence: ${result.confidence}');

      if (result.hasConfidenceRating && result.confidence < 0.4) {
        print('[Voice] Ignoring low-confidence match');
        return;
      }

      // ⚡ FAST PATH: Check local offline commands first (latency sensitive)
      final localCommand = _checkLocalCommands(recognized);
      if (localCommand != null) {
        _lastVoiceTrigger = now;
        _executeAction(localCommand['action']!, localCommand['value']);
        return;
      }

      // 🧠 SMART PATH: Use Gemini AI Agent for complex intent
      // Running in background to not block UI, but actionable
      _processWithAI(recognized);

    } catch (e) {
      print('[Voice] Error: $e');
    }
  }

  Map<String, String>? _checkLocalCommands(String text) {
    // 1. Direct Calls
    final callCommands = {
      'call police': '100', 'police ko call': '100', 'police bulao': '100',
      'call ambulance': '102', 'ambulance bulao': '102',
      'call fire': '101', 'aag lagi': '101',
      'call helpline': '112', 'one one two': '112',
    };

    for (final entry in callCommands.entries) {
      if (text.contains(entry.key)) return {'action': 'CALL', 'value': entry.value};
    }

    // 2. SOS Triggers
    const sosKeywords = ['help me', 'sos', 'bachao', 'madad', 'save me'];
    if (sosKeywords.any((k) => text.contains(k))) return {'action': 'SOS', 'value': ''};

    return null;
  }

  Future<void> _processWithAI(String text) async {
    try {
      print('[Voice] 🧠 Asking AI Agent...');
      final decision = await GeminiService.classifyVoiceCommand(text);
      print('[Voice] 🧠 Agent Decision: $decision');

      if (decision['confidence'] > 0.7) {
        final action = decision['action'];
        
        // Execute AI decision
        if (action == 'CALL_POLICE') _executeAction('CALL', '100');
        else if (action == 'CALL_AMBULANCE') _executeAction('CALL', '102');
        else if (action == 'CALL_FIRE') _executeAction('CALL', '101');
        else if (action == 'CALL_HELPLINE') _executeAction('CALL', '112');
        else if (action == 'TRIGGER_SOS') _executeAction('SOS', '');
      }
    } catch (e) {
      print('[Voice] AI processing error: $e');
    }
  }

  void _executeAction(String action, String? value) {
    _lastVoiceTrigger = DateTime.now();
    
    if (action == 'CALL') {
      print('[Action] 📞 Direct calling $value');
      _makeEmergencyCall(value!);
      _showCallFeedback('Emergency Call', value);
      // Also send SOS to server when calling emergency services
      _sendSOSViaWebSocket('CALL_$value');
    } else if (action == 'SOS') {
      print('[Action] 🆘 Triggering SOS via server');
      _sendSOSViaWebSocket('VOICE_SOS');
      _handleVoiceTriggeredSOS();
    }
  }

  /// Send SOS directly to backend via WebSocket (no SMS app needed)
  void _sendSOSViaWebSocket(String triggerType) {
    try {
      print('[SOS] 🚨 Sending emergency to server: $triggerType');
      WebSocketService().emitEmergency();
    } catch (e) {
      print('[SOS] WebSocket error: $e');
    }
  }

  void _showCallFeedback(String command, String number) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Calling $number...'),
        backgroundColor: AppColors.navyBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _handleSpeechError(String message) {
    if (!mounted) return;
    setState(() {
      _isListeningForHelp = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startListeningForHelp();
      }
    });
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListeningForHelp = false;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _startListeningForHelp();
        }
      });
    }
  }

  void _handleVoiceTriggeredSOS() {
    if (!mounted) return;
    print('[SOS] Voice trigger detected, calling _sendSOSAlert');
    _sendSOSAlert();
    setState(() {
      print('[SOS] setState: _sosPressed = true');
      _sosPressed = true;
    });
    // Reset button after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          print('[SOS] setState: _sosPressed = false');
          _sosPressed = false;
        });
      }
    });
  }

  Future<void> _sendSOSAlert() async {
    print('[SOS] _sendSOSAlert called');
    // Get Emergency Contacts first (fast, no network)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contacts = authProvider.emergencyContacts;
    
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contacts found. Please add them in Profile.')),
        );
      }
      return;
    }

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🆘 Sending SOS Alert...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Get location with timeout (don't block on slow GPS)
    Position? position;
    try {
      position = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      print('Location timeout or error: $e');
      // Try to get last known position as fallback
      try {
        position = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(milliseconds: 500));
      } catch (e2) {
        print('No last known position: $e2');
        // Continue without location - still send SOS
      }
    }

    // Build message with available location
    String locationUrl = 'Location unavailable';
    double? lat, lng;
    if (position != null) {
      lat = position.latitude;
      lng = position.longitude;
      locationUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      // Set incident location for geofence
      if (lat != null && lng != null) {
        final double latValue = lat;
        final double lngValue = lng;
        setState(() {
          _incidentLocation = LatLng(latValue, lngValue);
        });
      }
    }

    final phoneNumbers = contacts.map((e) => e['phone']).join(',');
    final message = position != null
        ? '🆘 SOS! I need immediate help!\n\nMy location: $locationUrl\nCoordinates: $lat, $lng\nTime: ${DateTime.now().toString()}\n\nPlease respond immediately!'
        : '🆘 SOS! I need immediate help!\n\nTime: ${DateTime.now().toString()}\n\nPlease respond immediately!';
    
    // OPEN SMS APP IMMEDIATELY (don't wait for backend)
    try {
      final smsUri = Uri.parse('sms:$phoneNumbers?body=${Uri.encodeComponent(message)}');
      print('[SOS] Sending SMS with URI: $smsUri');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      print('[SOS] SMS intent launched');
    } catch (e) {
      print('[SOS] Error opening SMS app: $e');
    }

    // Run backend operations in background (non-blocking)
    if (position != null) {
      _sendSOSBackground(
        latitude: position.latitude,
        longitude: position.longitude,
        contacts: contacts,
        userName: authProvider.user?.name ?? authProvider.user?.email,
      );
    } else {
      // Still try to send to Firestore even without location
      _sendSOSBackground(
        latitude: null,
        longitude: null,
        contacts: contacts,
        userName: authProvider.user?.name ?? authProvider.user?.email,
      );
    }
  }

  // Background task - doesn't block UI
  void _sendSOSBackground({
    required double? latitude,
    required double? longitude,
    required List<Map<String, dynamic>> contacts,
    String? userName,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 'unknown';
      
      // Send alert to new backend API (fire and forget - no await)
      if (latitude != null && longitude != null) {
        // Check if user is authenticated with new backend
        final isAuthenticated = await BackendService.isAuthenticated();
        if (isAuthenticated) {
          unawaited(() async {
            try {
              await BackendService.createAlert(
                alertType: 'sos',
                lat: latitude,
                lng: longitude,
                message: 'SOS Alert from ${userName ?? "User"}',
              ).timeout(const Duration(seconds: 5));
            } catch (error) {
              print('New backend alert error (non-critical): $error');
            }
          }());
        }

        // Also log SOS as an incident in the NestJS incidents table
        unawaited(() async {
          try {
            await ApiService.reportIncident({
              'title': 'SOS Alert',
              'description':
                  'SOS triggered by ${userName ?? userId} at $latitude, $longitude',
              'category': 'SOS',
              'urgency': 'Critical',
              'location': {
                'latitude': latitude,
                'longitude': longitude,
              },
              'address': null,
              'userId': userId,
              'reportedAt': DateTime.now().toIso8601String(),
            });
          } catch (error) {
            print('Incident logging error (non-critical): $error');
          }
        }());
        
        // Also send to old backend (fire and forget - no await)
        unawaited(() async {
          try {
            await ApiService.sendSOS(
              latitude: latitude,
              longitude: longitude,
              emergencyContacts: contacts,
              userName: userName,
            ).timeout(const Duration(seconds: 5));
          } catch (error) {
            print('Backend SMS error (non-critical): $error');
          }
        }());
      }

      // Send to Firestore (fire and forget - no await)
      unawaited(() async {
        try {
          await FirebaseFirestore.instance.collection('alerts').add({
            'alert_type': 'SOS',
            if (latitude != null && longitude != null) 'location': {
              'latitude': latitude,
              'longitude': longitude,
              'timestamp': DateTime.now(),
              'type': 'SOS',
            },
            'user_id': userId,
            'timestamp': DateTime.now(),
            'status': 'active',
            'contacts_notified': contacts.length,
          }).timeout(const Duration(seconds: 3));
        } catch (error) {
          print('Firestore error (non-critical): $error');
        }
      }());
    } catch (e) {
      // All background errors are non-critical
      print('Background SOS task error: $e');
    }
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    try {
      // Use platformDefault for direct dialing (requires CALL_PHONE permission on Android)
      // This will directly start the call without showing dialer
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        // Fallback to external app if direct dial fails
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching dialer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB), // Surface white
          appBar: AppBar(
            title: Text(
              tr('emergency'),
              style: const TextStyle(
                color: AppColors.navyBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.navyBlue),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Voice Status
                Center(child: _buildVoiceStatusBanner()),
                const SizedBox(height: 30),

                // SOS Button Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        tr('Are you in emergency ?'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('Press SOS'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSOSButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Emergency Services Grid
                // Text(
                //   // tr('Emergency Services'),
                //   style: const TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //     color: AppColors.textDark,
                //   ),
                // ),
                const SizedBox(height: 16),
                _buildContactsGrid(),

                const SizedBox(height: 30),

                // Incident Report Button
                _buildActionButtons(),

                const SizedBox(height: 100), // Added extra padding for scrolling
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        if (!_sosPressed) {
          _showSOSConfirmDialog();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _sosPressed
                ? [AppColors.indiaGreen, Colors.greenAccent]
                : [AppColors.error, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_sosPressed ? AppColors.indiaGreen : AppColors.error).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
              _sosPressed ? Icons.check_circle_outline : Icons.sos,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _sosPressed ? tr('sent') : tr('sos'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStatusBanner() {
    Color statusColor;
    IconData icon;
    String label;

    if (!_speechEnabled) {
      statusColor = AppColors.grey;
      icon = Icons.mic_off;
      label = tr('voice_control_unavailable');
    } else if (_isListeningForHelp) {
      statusColor = AppColors.indiaGreen;
      icon = Icons.hearing;
      label = tr('voice_control_listening');
    } else {
      statusColor = AppColors.saffron;
      icon = Icons.mic;
      label = tr('voice_control_ready');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsGrid() {
    final contacts = [
      {
        'name': tr('police'),
        'icon': Icons.local_police_outlined,
        'color': AppColors.navyBlue,
        'number': '100'
      },
      {
        'name': tr('fire'),
        'icon': Icons.local_fire_department_outlined,
        'color': AppColors.saffron,
        'number': '101'
      },
      {
        'name': tr('ambulance'),
        'icon': Icons.medical_services_outlined,
        'color': AppColors.error,
        'number': '102'
      },
      {
        'name': 'Helpline',
        'icon': Icons.support_agent,
        'color': Colors.purple,
        'number': '112'
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return InkWell(
          onTap: () => _makeEmergencyCall(contact['number'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (contact['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    contact['icon'] as IconData,
                    color: contact['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  contact['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact['number'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    TextEditingController _vehicleController = TextEditingController();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.navyBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    hintText: 'Share Vehicle Number',
                    hintStyle: TextStyle(color: AppColors.textGrey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.navyBlue),
                onPressed: () {
                  // Handle send logic
                  _vehicleController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle details shared with contacts')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IncidentReportScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('report_incident'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Report unsafe conditions or incidents',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSOSConfirmDialog({bool triggeredByVoice = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            tr('sos_alert'),
            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          content: Text(
            triggeredByVoice
                ? tr('voice_sos_alert_message')
                : tr('sos_alert_message'),
            style: const TextStyle(fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('cancel'),
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendSOSAlert();
                setState(() {
                  _sosPressed = true;
                });
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    setState(() {
                      _sosPressed = false;
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                tr('send_sos_alert'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
