import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { DeepseekService } from './deepseek.service';

@Module({
  controllers: [ChatController],
  providers: [DeepseekService],
  exports: [DeepseekService],
})
export class ChatModule {}
