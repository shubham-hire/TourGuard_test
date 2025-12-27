import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { GeminiChatService } from './gemini-chat.service';

@Module({
  controllers: [ChatController],
  providers: [GeminiChatService],
  exports: [GeminiChatService],
})
export class ChatModule {}
