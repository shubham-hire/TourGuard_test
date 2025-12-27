import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';

/// WebSocket service for real-time communication with backend
/// Singleton pattern - persists across navigation
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  final _safetyScoreController = StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyAckController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Connection state
  bool _isInitialized = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Streams for UI to listen to
  Stream<Map<String, dynamic>> get safetyScoreStream => _safetyScoreController.stream;
  Stream<Map<String, dynamic>> get emergencyAckStream => _emergencyAckController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;
  bool get isInitialized => _isInitialized;

  void init() {
    if (_isInitialized) {
      print('[WebSocket] Already initialized, skipping');
      return;
    }

    // Production: Render deployment
    const String backendUrl = 'https://tourguard-test.onrender.com';

    try {
      _socket = IO.io(backendUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(3000)
          .build());

      _setupEventHandlers(backendUrl);
      _socket!.connect();
      _isInitialized = true;
      
    } catch (e) {
      print('[WebSocket] ❌ Init error: $e');
      _connectionStatusController.add(false);
      _scheduleReconnect();
    }
  }

  void _setupEventHandlers(String backendUrl) {
    _socket!.onConnect((_) {
      print('[WebSocket] ✅ Connected to $backendUrl');
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((_) {
      print('[WebSocket] ❌ Disconnected');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      print('[WebSocket] ⚠️ Connection error: $error');
      _connectionStatusController.add(false);
    });

    _socket!.onError((error) {
      print('[WebSocket] ⚠️ Socket error: $error');
    });

    _socket!.onReconnect((_) {
      print('[WebSocket] 🔄 Reconnected');
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
    });

    _socket!.onReconnectAttempt((attempt) {
      print('[WebSocket] 🔄 Reconnect attempt $attempt/$_maxReconnectAttempts');
      _reconnectAttempts = attempt as int;
    });

    _socket!.onReconnectFailed((_) {
      print('[WebSocket] ❌ Reconnection failed after $_maxReconnectAttempts attempts');
      _connectionStatusController.add(false);
    });

    // Business events
    _socket!.on('safety:score', (data) {
      try {
        print('[WebSocket] 📊 Received safety score: $data');
        if (data != null) {
          _safetyScoreController.add(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('[WebSocket] ⚠️ Error parsing safety score: $e');
      }
    });

    _socket!.on('emergency:ack', (data) {
      try {
        print('[WebSocket] 🚨 Emergency ACK: $data');
        if (data != null) {
          _emergencyAckController.add(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print('[WebSocket] ⚠️ Error parsing emergency ack: $e');
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[WebSocket] ❌ Max reconnect attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    print('[WebSocket] 🔄 Scheduling reconnect in ${_reconnectDelay.inSeconds}s (attempt $_reconnectAttempts)');
    
    Future.delayed(_reconnectDelay, () {
      if (!isConnected) {
        _socket?.connect();
      }
    });
  }

  void emitLocation(Position position) {
    if (_socket == null || !_socket!.connected) {
      print('[WebSocket] ⚠️ Cannot emit location - not connected');
      return;
    }
    
    try {
      _socket!.emit('location:update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[WebSocket] ⚠️ Error emitting location: $e');
    }
  }

  void emitEmergency() {
    if (_socket == null || !_socket!.connected) {
      print('[WebSocket] ⚠️ Cannot emit emergency - not connected');
      // Still try to connect and emit
      _socket?.connect();
      return;
    }
    
    try {
      print('[WebSocket] 🆘 Sending Emergency Trigger...');
      _socket!.emit('emergency:trigger', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[WebSocket] ⚠️ Error emitting emergency: $e');
    }
  }

  /// Force reconnect manually
  void reconnect() {
    print('[WebSocket] 🔄 Manual reconnect requested');
    _socket?.disconnect();
    _reconnectAttempts = 0;
    Future.delayed(const Duration(milliseconds: 500), () {
      _socket?.connect();
    });
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _isInitialized = false;
    _safetyScoreController.close();
    _emergencyAckController.close();
    _connectionStatusController.close();
  }
}
