import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    if (userId) {
      client.join(`user:${userId}`);
    }
  }

  handleDisconnect(client: Socket) {
    // Cleanup handled automatically
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: {
      receiverId: string;
      message: string;
      bookingId?: string;
    },
  ) {
    const userId = client.handshake.query.userId as string;
    if (!userId) return;

    const message = await this.chatService.sendMessage(userId, payload);

    // Emit to receiver's room
    this.server.to(`user:${payload.receiverId}`).emit('new_message', message);
    // Emit back to sender
    client.emit('new_message', message);
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { messageId: string },
  ) {
    const userId = client.handshake.query.userId as string;
    if (!userId) return;
    await this.chatService.markAsRead(payload.messageId, userId);
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { receiverId: string },
  ) {
    const userId = client.handshake.query.userId as string;
    if (!userId) return;
    this.server
      .to(`user:${payload.receiverId}`)
      .emit('user_typing', { userId });
  }
}
