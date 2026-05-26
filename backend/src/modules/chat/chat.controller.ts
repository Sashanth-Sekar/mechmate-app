import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ChatService } from './chat.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('chat')
@UseGuards(AuthGuard('jwt'))
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('send')
  async sendMessage(
    @CurrentUser() user: { id: string },
    @Body() dto: { receiverId: string; message: string; bookingId?: string },
  ) {
    return this.chatService.sendMessage(user.id, dto);
  }

  @Get('conversations')
  async getConversations(@CurrentUser() user: { id: string }) {
    return this.chatService.getConversations(user.id);
  }

  @Get('conversation/:otherUserId')
  async getConversation(
    @CurrentUser() user: { id: string },
    @Param('otherUserId') otherUserId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.chatService.getConversation(user.id, otherUserId, {
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 50,
    });
  }

  @Patch('read/:messageId')
  async markAsRead(
    @Param('messageId') messageId: string,
    @CurrentUser() user: { id: string },
  ) {
    return this.chatService.markAsRead(messageId, user.id);
  }
}
