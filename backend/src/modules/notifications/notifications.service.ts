import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from '../../database/entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
  ) {}

  async create(dto: {
    userId: string;
    title: string;
    body: string;
    type: string;
    referenceId?: string;
  }): Promise<Notification> {
    const notification = this.notificationRepo.create({
      userId: dto.userId,
      title: dto.title,
      body: dto.body,
      type: dto.type,
      referenceId: dto.referenceId,
    });

    return this.notificationRepo.save(notification);
  }

  async findAll(
    userId: string,
    filters: { unreadOnly?: boolean; page?: number; limit?: number } = {},
  ) {
    const { unreadOnly, page = 1, limit = 20 } = filters;
    const where: any = { userId };

    if (unreadOnly) {
      where.isRead = false;
    }

    const [data, total] = await this.notificationRepo.findAndCount({
      where,
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    const unreadCount = await this.notificationRepo.count({
      where: { userId, isRead: false },
    });

    return {
      data,
      total,
      unreadCount,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async markAsRead(id: string, userId: string) {
    await this.notificationRepo.update(
      { id, userId },
      { isRead: true },
    );
    return { success: true };
  }

  async markAllAsRead(userId: string) {
    await this.notificationRepo.update(
      { userId, isRead: false },
      { isRead: true },
    );
    return { success: true };
  }

  async delete(id: string, userId: string) {
    await this.notificationRepo.delete({ id, userId });
    return { success: true };
  }
}
