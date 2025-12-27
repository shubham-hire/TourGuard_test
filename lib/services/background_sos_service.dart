import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSosService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initializeVerifier() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  static Future<void> trigger() async {
    try {
      await initializeVerifier();
      await _showNotification('SOS Initiated', 'Getting your location...');

      // Attempt to load env (might fail in background isolate if assets not ready)
      // Use the production URL by default to match BackendService
      String baseUrl = 'https://tourguard-test.onrender.com/api'; 
      try {
        await dotenv.load(fileName: ".env");
        baseUrl = dotenv.env['API_URL'] ?? baseUrl;
      } catch (e) {
        print("Env load failed in background: $e");
      }

      // Get Location
      Position? position;
      try {
         position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high, 
            timeLimit: const Duration(seconds: 5)
         );
      } catch (e) {
        print("Location error: $e");
      }

      // Prepare Data
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id'); // Key from BackendService
      final token = prefs.getString('auth_token');

      // Send to Backend
      // Endpoint: /sos-alerts (POST) - Validated in backend code
      final url = Uri.parse('$baseUrl/sos-alerts');
      
      await _showNotification('Sending Alert', 'Contacting server...');

      // Note: SOS endpoint might be public, but sending token is good practice
      final headers = {
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      try {
          final response = await http.post(
            url,
            headers: headers,
            body: jsonEncode({
              if (userId != null) 'userId': userId,
              'latitude': position?.latitude ?? 0.0,
              'longitude': position?.longitude ?? 0.0,
              'message': 'SOS Widget Triggered (Background)',
            }),
          );

          print("Background SOS Response: ${response.statusCode} ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
             await _showNotification(
                'SOS Sent! 🚨', 
                'Emergency contacts have been notified.'
             );
          } else {
             await _showNotification('SOS Failed', 'Server error: ${response.statusCode}');
          }
      } catch (e) {
         print("Network error: $e");
         await _showNotification('SOS Failed', 'Network error');
      }

    } catch (e) {
      print("Background SOS Error: $e");
      await _showNotification('SOS Error', 'Please open app to send SOS');
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel_bg', 'SOS Background',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.show(777, title, body, details);
  }
}
