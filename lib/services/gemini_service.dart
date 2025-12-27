import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static GenerativeModel? _cachedModel;

  static GenerativeModel _model() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is missing. Pass --dart-define=GEMINI_API_KEY=your_key when running the app.',
      );
    }

    _cachedModel ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    return _cachedModel!;
  }

  static Future<String> generateSafetyInsights(String prompt) async {
    try {
      final model = _model();
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini returned an empty response');
      }

      return text.trim();
    } on StateError catch (e) {
      throw Exception('Gemini API key not configured: ${e.message}');
    } catch (e) {
      throw Exception('Gemini API error: $e');
    }
  }
  static Future<Map<String, dynamic>> classifyVoiceCommand(String input) async {
    try {
      final model = _model();
      final prompt = '''
      You are an autonomous emergency assistant. Classify the user's voice input into one of these actions:
      - CALL_POLICE (e.g. 'call cops', 'police', 'someone is following me', 'robbery', 'thief', 'chori', 'chor')
      - CALL_AMBULANCE (e.g. 'hurt', 'blood', 'accident', 'ambulance', 'medical', 'broken leg', 'heart attack')
      - CALL_FIRE (e.g. 'fire', 'burning', 'smoke', 'aag lagi')
      - CALL_HELPLINE (e.g. 'help me', 'support', 'guide me', 'need assistance')
      - TRIGGER_SOS (e.g. 'sos', 'save me', 'in danger', 'bachao', 'madad', 'khatra')
      - NONE (if unclear, irrelevant, or just conversation)

      User input: "$input"

      Return ONLY a VALID JSON object (no markdown, no backticks):
      { "action": "ACTION_NAME", "confidence": 0.0 to 1.0 }
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      var text = response.text?.trim() ?? '{}';
      
      // Clean markdown if present
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Basic JSON parsing manually if needed, or better use dart:convert
      // Since specific imports might be missing, we'll return a raw map from parsing
      // assuming the caller will import dart:convert.
      // But wait, this file doesn't import dart:convert. Let's return raw string and parse in caller
      // OR better, add import 'dart:convert'; to top of file in a separate step? 
      // No, let's keep it simple and string parsing or add import now.
      
      return _parseJsonLike(text);

    } catch (e) {
      print('Gemini classification error: $e');
      return {'action': 'NONE', 'confidence': 0.0};
    }
  }

  static Map<String, dynamic> _parseJsonLike(String text) {
    // Simple manual parser fallback if dart:convert not imported
    // But ideally we should rely on dart:convert.
    // Let's rely on simple string matching for robustness without imports
    String action = 'NONE';
    double confidence = 0.0;
    
    if (text.contains('"action":')) {
      final match = RegExp(r'"action":\s*"([^"]+)"').firstMatch(text);
      if (match != null) action = match.group(1) ?? 'NONE';
    }
    
    if (text.contains('"confidence":')) {
      final match = RegExp(r'"confidence":\s*([\d\.]+)').firstMatch(text);
      if (match != null) confidence = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }

    return {'action': action, 'confidence': confidence};
  }
}

