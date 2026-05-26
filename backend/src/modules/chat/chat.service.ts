import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessage } from '../../database/entities/chat-message.entity';
import { User } from '../../database/entities/user.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatMessage)
    private readonly messageRepo: Repository<ChatMessage>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async sendMessage(
    senderId: string,
    dto: {
      receiverId: string;
      message: string;
      bookingId?: string;
    },
  ): Promise<ChatMessage> {
    const message = this.messageRepo.create({
      senderId,
      receiverId: dto.receiverId,
      message: dto.message,
      bookingId: dto.bookingId,
    });

    return this.messageRepo.save(message);
  }

  async getConversation(
    userId: string,
    otherUserId: string,
    filters: { page?: number; limit?: number } = {},
  ) {
    const { page = 1, limit = 50 } = filters;

    const [data, total] = await this.messageRepo.findAndCount({
      where: [
        { senderId: userId, receiverId: otherUserId },
        { senderId: otherUserId, receiverId: userId },
      ],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      data: data.reverse(),
      total,
      page,
      limit,
    };
  }

  async getConversations(userId: string) {
    const sent = await this.messageRepo
      .createQueryBuilder('message')
      .where('message.senderId = :userId', { userId })
      .select('DISTINCT message.receiverId', 'receiverId')
      .getRawMany();

    const received = await this.messageRepo
      .createQueryBuilder('message')
      .where('message.receiverId = :userId', { userId })
      .select('DISTINCT message.senderId', 'senderId')
      .getRawMany();

    const userIds = new Set<string>();
    sent.forEach((r: any) => userIds.add(r.receiverId));
    received.forEach((r: any) => userIds.add(r.senderId));

    const conversations: any[] = [];

    for (const otherId of userIds) {
      const otherUser = await this.userRepo.findOne({
        where: { id: otherId },
      });
      if (!otherUser) continue;

      const lastMessage = await this.messageRepo.findOne({
        where: [
          { senderId: userId, receiverId: otherId },
          { senderId: otherId, receiverId: userId },
        ],
        order: { createdAt: 'DESC' },
      });

      const unreadCount = await this.messageRepo.count({
        where: {
          senderId: otherId,
          receiverId: userId,
          isRead: false,
        },
      });

      conversations.push({
        user: {
          id: otherUser.id,
          name: otherUser.name,
          phone: otherUser.phone,
          role: otherUser.role,
        },
        lastMessage,
        unreadCount,
      });
    }

    return conversations.sort(
      (a, b) =>
        (b.lastMessage?.createdAt?.getTime() || 0) -
        (a.lastMessage?.createdAt?.getTime() || 0),
    );
  }

  async markAsRead(messageId: string, userId: string) {
    await this.messageRepo.update(
      { id: messageId, receiverId: userId },
      { isRead: true },
    );
    return { success: true };
  }
}
