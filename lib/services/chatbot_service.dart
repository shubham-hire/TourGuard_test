import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ChatbotService {
  static const String boxName = 'chatbotBox';
  static List<ChatMessage> _messages = [];
  static final List<Function(ChatMessage)> _listeners = [];
  static int _unreadCount = 0; // Track unread bot messages
  
  static int get unreadCount => _unreadCount;
  static void resetUnreadCount() => _unreadCount = 0;

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    await _loadMessages();
  }

  static Future<void> _loadMessages() async {
    try {
      final box = Hive.box(boxName);
      final saved = box.get('messages', defaultValue: []) as List<dynamic>;
      _messages = saved.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  static List<ChatMessage> getMessages() => _messages;

  static Future<void> sendMessage(String text) async {
    // Don't send empty messages (initial greeting handled below)
    if (text.isNotEmpty) {
      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
      _messages.add(msg);
      _notifyListeners(msg);
      await _saveMessages();
    }

    // Get AI response from backend
    String botResponse;
    try {
      botResponse = await _getAIResponse(text);
    } catch (e) {
      print('AI API failed, using fallback: $e');
      botResponse = _getFallbackResponse(text);
    }

    final botMsg = ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      text: botResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(botMsg);
    _unreadCount++; // Increment unread for badge
    _notifyListeners(botMsg);
    await _saveMessages();
  }

  /// Calls the backend DeepSeek AI API
  static Future<String> _getAIResponse(String userText) async {
    const String baseUrl = 'https://tourguard-test.onrender.com'; // Your backend
    // For local dev: 'http://localhost:3000'
    
    try {
      final uri = Uri.parse('$baseUrl/chat');
      final response = await _httpPost(uri, {
        'message': userText.isEmpty ? 'Hello' : userText,
      });

      if (response != null && response['success'] == true) {
        return response['response'] as String;
      } else {
        throw Exception('Invalid API response');
      }
    } catch (e) {
      print('Chat API error: $e');
      rethrow;
    }
  }

  /// Simple HTTP POST helper
  static Future<Map<String, dynamic>?> _httpPost(Uri uri, Map<String, dynamic> body) async {
    try {
      // Using dart:io HttpClient for simplicity
      final request = await HttpClient().postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(body));
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('HTTP error: $e');
      return null;
    }
  }

  /// Fallback responses when API is unavailable
  static String _getFallbackResponse(String userText) {
    final lower = userText.toLowerCase();

    if (lower.contains('e-fir') || lower.contains('fir')) {
      return '📋 I can guide you through the E-FIR process. I will need your UID from your profile and the incident details. Would you like to start?';
    }

    if (lower.contains('incident') || lower.contains('report')) {
      return '🚨 Reporting an incident will alert the nearest Help Center and update the global safety heatmap. Tap the "Report" button to send your live coordinates.';
    }

    if (lower.contains('sos') || lower.contains('emergency') || lower.contains('help')) {
      return '🆘 I have alerted the emergency dispatcher. Help is being routed to your coordinates. Stay on the line and check your "Emergency Section" for live tracking.';
    }

    if (lower.contains('nearby') || lower.contains('people') || lower.contains('traveler')) {
      return '👨‍👩‍👧‍👦 I see 12 Verified Travelers within 5km of you. 3 are currently in this chat hub. You can coordinate for group travel here safely.';
    }

    if (lower.contains('verified') || lower.contains('trust') || lower.contains('blockchain')) {
      return '🛡️ Users with a Green Badge are Blockchain-Verified. Their identity is anchored on the TourGuard Ledger, ensuring a high level of trust and safety.';
    }

    if (lower.contains('zone') || lower.contains('safe') || lower.contains('danger')) {
      return '🛡️ Analyzing your current coordinates... You are in a "Caution" zone due to high crowd density. I recommend staying in well-lit areas.';
    }

    // Default response
    return 'नमस्ते (Namaste)! I am your AI Guardian. I monitor local safety data 24/7. \n\nI can help you:\n• Connect with nearby travelers\n• Report safety hazards\n• Verify local trust scores\n• Trigger emergency SOS\n\nHow can I protect you today?';
  }

  static void onMessage(Function(ChatMessage) callback) {
    _listeners.add(callback);
  }

  static void _notifyListeners(ChatMessage message) {
    for (var listener in _listeners) {
      listener(message);
    }
  }

  static Future<void> _saveMessages() async {
    try {
      final box = Hive.box(boxName);
      await box.put('messages', _messages.map((m) => m.toMap()).toList());
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  static Future<void> clearMessages() async {
    _messages.clear();
    final box = Hive.box(boxName);
    await box.delete('messages');
  }

  static List<String> getSuggestions() {
    return [
      '👥 Nearby Travelers',
      '🚨 Report Hazard',
      '🛡️ Is this area safe?',
      '📋 My Safety Status',
      '🆘 Emergency SOS',
      '🌍 Translate chat',
    ];
  }
}
