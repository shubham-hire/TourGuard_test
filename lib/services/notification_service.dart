import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final MethodChannel _platform = MethodChannel('tourapp/notifications');
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  static bool _initialized = false;

  static Future<void> initialize() async {
    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings (if needed)
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap if needed
        },
      );

      // Create notification channels for Android
      await _createNotificationChannels();
      
      _initialized = true;
      debugPrint('NotificationService initialized with flutter_local_notifications');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
      // Fallback to platform channel
      _initialized = false;
    }
  }

  static Future<void> _createNotificationChannels() async {
    if (_flutterLocalNotificationsPlugin == null) return;

    // Geofence notification channel - optimized for speed
    const AndroidNotificationChannel geofenceChannel = AndroidNotificationChannel(
      'geofence_alerts',
      'Geofence Alerts',
      description: 'Notifications for entering and exiting geofence zones',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Emergency notification channel
    const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'Emergency Alerts',
      description: 'Emergency and SOS notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(geofenceChannel);

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);
  }

  static Future<void> showAlertNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // Use flutter_local_notifications if initialized
      if (_initialized && _flutterLocalNotificationsPlugin != null) {
        String channelId = 'geofence_alerts';
        Importance importance = Importance.high;
        Priority priority = Priority.high;
        bool playSound = true;
        bool enableVibration = true;

        // Adjust settings based on notification type
        if (type == 'emergency' || type.contains('emergency')) {
          channelId = 'emergency_alerts';
          importance = Importance.max;
          priority = Priority.max;
        } else if (type == 'geofence_enter' || type == 'geofence_exit') {
          channelId = 'geofence_alerts';
          importance = Importance.high;
          priority = Priority.high;
        }

        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'geofence_alerts',
          'Geofence Alerts',
          channelDescription: 'Notifications for entering and exiting geofence zones',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
          showWhen: true,
          when: null, // Show immediately
          ticker: '', // No ticker for faster display
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Generate unique ID based on timestamp to avoid notification replacement
        final int notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

        // Show notification immediately without await to make it faster
        _flutterLocalNotificationsPlugin!.show(
          notificationId,
          title,
          body,
          notificationDetails,
        );

        debugPrint('Notification queued: $title - $body');
      } else {
        // Fallback to platform channel
        await _platform.invokeMethod('showNotification', {
          'title': title,
          'body': body,
          'type': type,
        });
      }
    } catch (e) {
      debugPrint('NotificationService error: $e');
      // Try platform channel as last resort
      try {
        await _platform.invokeMethod('showNotification', {
          'title': title,
          'body': body,
        });
      } catch (platformError) {
        debugPrint('Platform channel notification also failed: $platformError');
      }
    }
  }

  static Future<void> showEmergencyNotification() async {
    await showAlertNotification(
      title: 'Emergency',
      body: 'Emergency triggered',
      type: 'emergency',
    );
  }
}