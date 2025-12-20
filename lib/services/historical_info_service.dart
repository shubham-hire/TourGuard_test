import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for generating historical and cultural information about places
class HistoricalInfoService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? ''; // Your Gemini API key
  static GenerativeModel? _model;

  static GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    return _model!;
  }

  /// Generate historical information for a place
  static Future<Map<String, dynamic>> getHistoricalInfo(
    String placeName,
    String category,
    double latitude,
    double longitude,
  ) async {
    try {
      final prompt = '''
You are a knowledgeable tour guide providing fascinating historical and cultural information.

Place: $placeName
Category: $category
Location: $latitude, $longitude

Provide the following information in a structured format:

1. HISTORICAL_STORY (2-3 sentences): A brief, engaging story about this place's history
2. CULTURAL_SIGNIFICANCE (1-2 sentences): Why this place is culturally important
3. BEST_TIME (1 sentence): Best time of day or season to visit
4. LOCAL_TIP (1 sentence): An insider tip that tourists should know
5. FUN_FACT (1 sentence): An interesting or surprising fact
6. RATING_ADVENTURE (1-5): Adventure level if applicable
7. RATING_HISTORICAL (1-5): Historical significance rating

Format your response exactly like this:
HISTORICAL_STORY: [your text here]
CULTURAL_SIGNIFICANCE: [your text here]
BEST_TIME: [your text here]
LOCAL_TIP: [your text here]
FUN_FACT: [your text here]
RATING_ADVENTURE: [number]
RATING_HISTORICAL: [number]

Keep responses authentic and informative. If you don't have specific information, provide general context for the area.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final text = response.text ?? '';
      
      // Parse the response
      final result = <String, dynamic>{};
      final lines = text.split('\n');
      
      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();
            
            switch (key) {
              case 'HISTORICAL_STORY':
                result['historicalStory'] = value;
                break;
              case 'CULTURAL_SIGNIFICANCE':
                result['culturalSignificance'] = value;
                break;
              case 'BEST_TIME':
                result['bestTime'] = value;
                break;
              case 'LOCAL_TIP':
                result['localTip'] = value;
                break;
              case 'FUN_FACT':
                result['funFact'] = value;
                break;
              case 'RATING_ADVENTURE':
                result['adventureRating'] = int.tryParse(value) ?? 0;
                break;
              case 'RATING_HISTORICAL':
                result['historicalRating'] = int.tryParse(value) ?? 0;
                break;
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Error fetching historical info: $e');
      return {
        'historicalStory': 'Discover the rich history of this location.',
        'culturalSignificance': 'This place holds special significance in local culture.',
        'bestTime': 'Visit during morning hours for the best experience.',
        'localTip': 'Ask locals for hidden perspectives.',
        'funFact': 'Every place has unique stories waiting to be discovered.',
        'adventureRating': 3,
        'historicalRating': 3,
      };
    }
  }
}
