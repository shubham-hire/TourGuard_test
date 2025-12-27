import { Controller, Post, Body, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { GeminiChatService } from './gemini-chat.service';

interface ChatRequestDto {
  message: string;
  history?: { role: 'user' | 'assistant'; content: string }[];
}

interface ChatResponseDto {
  success: boolean;
  response: string;
  timestamp: string;
}

@Controller('chat')
export class ChatController {
  private readonly logger = new Logger(ChatController.name);

  constructor(private readonly geminiChatService: GeminiChatService) {}

  @Post()
  async sendMessage(@Body() body: ChatRequestDto): Promise<ChatResponseDto> {
    const { message, history = [] } = body;

    if (!message || typeof message !== 'string') {
      throw new HttpException('Message is required', HttpStatus.BAD_REQUEST);
    }

    this.logger.log(`Received chat message: "${message.substring(0, 50)}..."`);

    try {
      const aiResponse = await this.geminiChatService.chat(message);
      
      return {
        success: true,
        response: aiResponse,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      this.logger.error('Chat error:', error);
      throw new HttpException(
        error.message || 'Failed to process chat',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('quick')
  async quickResponse(@Body() body: { query: string }): Promise<ChatResponseDto> {
    // Predefined quick responses for common queries (fallback if AI is slow)
    const quickResponses: Record<string, string> = {
      'emergency': '🆘 **Emergency Numbers:**\n• Police: 100\n• Ambulance: 108\n• Women Helpline: 1091\n• Tourist Helpline: 1363\n\nTap the SOS button for immediate help!',
      'safe': '🛡️ Analyzing your area... You appear to be in a moderate-safety zone. Stay in well-lit areas and keep your valuables secure.',
      'nearby': '👥 I see 10 Verified Travelers within 5km of you. 4 are currently active in this chat hub.',
      'translate': '🌍 Common phrases:\n• Hello = नमस्ते (Namaste)\n• Thank you = धन्यवाद (Dhanyavaad)\n• Help = मदद (Madad)\n• How much? = कितना? (Kitna?)',
    };

    const query = body.query?.toLowerCase() || '';
    
    for (const [key, response] of Object.entries(quickResponses)) {
      if (query.includes(key)) {
        return {
          success: true,
          response,
          timestamp: new Date().toISOString(),
        };
      }
    }

    // If no quick match, use AI
    return this.sendMessage({ message: body.query });
  }
}
