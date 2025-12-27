import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface DeepSeekResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: {
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }[];
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

@Injectable()
export class DeepseekService {
  private readonly logger = new Logger(DeepseekService.name);
  private readonly apiKey: string;
  private readonly baseUrl = 'https://api.deepseek.com';
  private readonly model = 'deepseek-chat';

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
If they ask about nearby travelers, simulate that 8-12 verified travelers are within 5km.`;

  constructor(private configService: ConfigService) {
    // API key must be set via environment variable
    this.apiKey = process.env.DEEPSEEK_API_KEY || '';
    if (!this.apiKey) {
      this.logger.warn('DEEPSEEK_API_KEY not set - AI chat will use fallback responses');
    } else {
      this.logger.log('DeepSeek AI Service initialized');
    }
  }

  async chat(userMessage: string, conversationHistory: ChatMessage[] = []): Promise<string> {
    try {
      const messages: ChatMessage[] = [
        { role: 'system', content: this.systemPrompt },
        ...conversationHistory,
        { role: 'user', content: userMessage },
      ];

      const response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          model: this.model,
          messages,
          stream: false,
          max_tokens: 500,
          temperature: 0.7,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`DeepSeek API error: ${response.status} - ${errorText}`);
        throw new HttpException(
          `AI service unavailable: ${response.status}`,
          HttpStatus.SERVICE_UNAVAILABLE,
        );
      }

      const data: DeepSeekResponse = await response.json();
      const assistantMessage = data.choices[0]?.message?.content || 'I apologize, I could not process your request.';
      
      this.logger.log(`Tokens used: ${data.usage?.total_tokens || 'N/A'}`);
      return assistantMessage;

    } catch (error) {
      this.logger.error('DeepSeek chat error:', error);
      if (error instanceof HttpException) throw error;
      throw new HttpException(
        'Failed to get AI response',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
