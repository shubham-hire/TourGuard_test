import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';

// Stream of real-time safety scores from backend
final safetyScoreProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return WebSocketService().safetyScoreStream;
});

// Stream of emergency acknowledgments
final emergencyAckProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return WebSocketService().emergencyAckStream;
});
