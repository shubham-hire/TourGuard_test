import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface GeminiResponse {
  candidates: {
    content: {
      parts: { text: string }[];
    };
    finishReason: string;
  }[];
  usageMetadata?: {
    promptTokenCount: number;
    candidatesTokenCount: number;
    totalTokenCount: number;
  };
}

@Injectable()
export class GeminiChatService {
  private readonly logger = new Logger(GeminiChatService.name);
  private readonly apiKey: string;
  private readonly baseUrl = 'https://generativelanguage.googleapis.com/v1';
  private readonly model = 'gemini-2.0-flash';

  // System prompt for the AI Guardian persona
  private readonly systemPrompt = `You are the **AI Guardian** for TourGuard, a Tourist Safety Application in India.
Your role is to:
1. Provide safety advice to tourists based on their location and situation.
2. Help with emergency procedures (SOS, E-FIR, incident reporting).
3. Translate basic phrases into local Indian languages when asked.
4. Inform about nearby verified travelers and safe zones.
5. Guide users on Indian travel etiquette, scams to avoid, and emergency contacts (Police: 100, Ambulance: 108, Women Helpline: 1091).

Be concise, helpful, and always prioritize user safety. Use emojis sparingly for visual clarity.
When greeting, use "नमस्ते (Namaste)!" to reflect local culture.
If the user asks about their current zone safety, simulate that they are in a "Caution" zone.
If they ask about nearby travelers, simulate that 8-12 verified travelers are within 5km.
Keep responses under 150 words.`;

  constructor(private configService: ConfigService) {
    // API key must be set via environment variable
    this.apiKey = process.env.GEMINI_API_KEY || '';
    if (!this.apiKey) {
      this.logger.warn('GEMINI_API_KEY not set - AI chat will use fallback responses');
    } else {
      this.logger.log('Gemini AI Chat Service initialized');
    }
  }

  async chat(userMessage: string): Promise<string> {
    if (!this.apiKey) {
      return this.getFallbackResponse(userMessage);
    }

    try {
      const url = `${this.baseUrl}/models/${this.model}:generateContent?key=${this.apiKey}`;
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: `${this.systemPrompt}\n\nUser: ${userMessage}` }
              ]
            }
          ],
          generationConfig: {
            maxOutputTokens: 300,
            temperature: 0.7,
          },
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`Gemini API error: ${response.status} - ${errorText}`);
        return this.getFallbackResponse(userMessage);
      }

      const data: GeminiResponse = await response.json();
      const assistantMessage = data.candidates?.[0]?.content?.parts?.[0]?.text || 
        'I apologize, I could not process your request.';
      
      this.logger.log(`Tokens used: ${data.usageMetadata?.totalTokenCount || 'N/A'}`);
      return assistantMessage;

    } catch (error) {
      this.logger.error('Gemini chat error:', error);
      return this.getFallbackResponse(userMessage);
    }
  }

  private getFallbackResponse(userText: string): string {
    const lower = userText.toLowerCase();

    if (lower.includes('emergency') || lower.includes('sos') || lower.includes('help')) {
      return '🆘 Emergency Numbers:\n• Police: 100\n• Ambulance: 108\n• Women Helpline: 1091\n• Tourist Helpline: 1363\n\nTap the SOS button for immediate help!';
    }

    if (lower.includes('safe') || lower.includes('zone') || lower.includes('danger')) {
      return '🛡️ Analyzing your area... You appear to be in a moderate-safety zone. Stay in well-lit areas and keep your valuables secure.';
    }

    if (lower.includes('nearby') || lower.includes('traveler') || lower.includes('people')) {
      return '👥 I see 10 Verified Travelers within 5km of you. 4 are currently active in this chat hub.';
    }

    if (lower.includes('translate') || lower.includes('hindi') || lower.includes('language')) {
      return '🌍 Common phrases:\n• Hello = नमस्ते (Namaste)\n• Thank you = धन्यवाद (Dhanyavaad)\n• Help = मदद (Madad)\n• How much? = कितना? (Kitna?)';
    }

    return 'नमस्ते (Namaste)! I am your AI Guardian. I monitor local safety data 24/7.\n\nI can help you:\n• Check zone safety\n• Connect with nearby travelers\n• Report incidents\n• Emergency SOS\n\nHow can I protect you today?';
  }
}
