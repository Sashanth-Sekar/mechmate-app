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

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class AppGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, string>(); // userId -> socketId
  private userSockets = new Map<string, Set<string>>(); // userId -> Set<socketId>

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    if (userId) {
      this.connectedUsers.set(userId, client.id);
      
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);
      
      client.join(`user:${userId}`);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.handshake.query.userId as string;
    if (userId) {
      const sockets = this.userSockets.get(userId);
      if (sockets) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
          this.connectedUsers.delete(userId);
        }
      }
    }
  }

  @SubscribeMessage('track_location')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: {
      userId: string;
      latitude: number;
      longitude: number;
      role: string;
    },
  ) {
    // Broadcast location to relevant rooms
    if (payload.role === 'mechanic') {
      // Broadcast to owners who have active bookings with this mechanic
      this.server
        .to(`tracking:${payload.userId}`)
        .emit('mechanic_location', {
          userId: payload.userId,
          latitude: payload.latitude,
          longitude: payload.longitude,
          timestamp: new Date().toISOString(),
        });
    }
  }

  @SubscribeMessage('subscribe_tracking')
  async handleSubscribeTracking(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { mechanicId: string },
  ) {
    client.join(`tracking:${payload.mechanicId}`);
  }

  @SubscribeMessage('unsubscribe_tracking')
  async handleUnsubscribeTracking(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { mechanicId: string },
  ) {
    client.leave(`tracking:${payload.mechanicId}`);
  }

  @SubscribeMessage('booking_update')
  async handleBookingUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: {
      bookingId: string;
      status: string;
      customerId: string;
      workshopId: string;
    },
  ) {
    this.server
      .to(`user:${payload.customerId}`)
      .emit('booking_status_update', {
        bookingId: payload.bookingId,
        status: payload.status,
      });

    this.server
      .to(`user:${payload.workshopId}`)
      .emit('booking_status_update', {
        bookingId: payload.bookingId,
        status: payload.status,
      });
  }

  // Send notification to specific user
  sendNotification(userId: string, notification: any) {
    this.server.to(`user:${userId}`).emit('notification', notification);
  }

  // Broadcast to all connected users
  broadcast(event: string, data: any) {
    this.server.emit(event, data);
  }

  isUserOnline(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }
}
