import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import {
  Booking,
  BookingStatus,
  BookingType,
} from '../../database/entities/booking.entity';
import { Workshop } from '../../database/entities/workshop.entity';
import { User } from '../../database/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Workshop)
    private readonly workshopRepo: Repository<Workshop>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(
    userId: string,
    dto: {
      workshopId: string;
      service: string;
      vehicleId: string;
      bookingType: BookingType;
      scheduledAt?: string;
      notes?: string;
      pickupLatitude?: number;
      pickupLongitude?: number;
      pickupAddress?: string;
    },
  ): Promise<Booking> {
    const workshop = await this.workshopRepo.findOne({
      where: { id: dto.workshopId },
    });
    if (!workshop) throw new NotFoundException('Workshop not found');

    const booking = this.bookingRepo.create({
      ownerId: userId,
      workshopId: dto.workshopId,
      vehicleId: dto.vehicleId,
      service: dto.service,
      bookingType: dto.bookingType,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : new Date(),
      notes: dto.notes,
      pickupLatitude: dto.pickupLatitude,
      pickupLongitude: dto.pickupLongitude,
      pickupAddress: dto.pickupAddress,
      status: BookingStatus.PENDING,
      isPaid: false,
      estimatedAmount: 0,
    });

    const saved = await this.bookingRepo.save(booking);

    const user = await this.userRepo.findOne({ where: { id: userId } });
    await this.notificationsService.create({
      userId: workshop.ownerId,
      title: 'New Booking',
      body: `New ${dto.bookingType} booking from ${user?.name || 'a user'}`,
      type: 'booking_update',
      referenceId: saved.id,
    });

    return saved;
  }

  async findAll(
    userId: string,
    role: string,
    filters: { status?: string; page?: number; limit?: number },
  ) {
    const { status, page = 1, limit = 20 } = filters;

    // Build where clause based on role
    const where: any = {};

    if (role === 'owner') {
      where.ownerId = userId;
    } else if (role === 'workshop') {
      // Resolve workshop IDs owned by this user first
      const workshops = await this.workshopRepo.find({
        where: { ownerId: userId },
        select: ['id'],
      });
      where.workshopId = In(workshops.map((w) => w.id));
    } else if (role === 'mechanic') {
      where.assignedMechanicId = userId;
    }

    if (status) {
      where.status = status;
    }

    // Use findAndCount which handles pagination + joins more reliably than
    // createQueryBuilder.getManyAndCount (avoids a known TypeORM issue with
    // leftJoinAndSelect + skip/take on SQLite)
    const [data, total] = await this.bookingRepo.findAndCount({
      where,
      relations: ['owner', 'workshop', 'vehicle'],
      order: { createdAt: 'DESC' as const },
      skip: (page - 1) * limit,
      take: limit,
    });

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(id: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id },
      relations: ['owner', 'workshop', 'vehicle'],
    });
    if (!booking) throw new NotFoundException('Booking not found');
    return booking;
  }

  async updateStatus(
    id: string,
    userId: string,
    role: string,
    newStatus: string,
  ): Promise<Booking> {
    const booking = await this.findOne(id);
    const validTransitions: Record<string, string[]> = {
      pending: ['confirmed', 'cancelled'],
      confirmed: ['active', 'cancelled'],
      active: ['completed', 'cancelled'],
      completed: [],
      cancelled: [],
    };

    const allowed = validTransitions[booking.status] || [];
    if (!allowed.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${booking.status} to ${newStatus}`,
      );
    }

    if (role === 'workshop' && ['confirmed', 'active', 'completed'].includes(newStatus)) {
      booking.status = newStatus as BookingStatus;
    } else if (role === 'owner' && newStatus === 'cancelled') {
      booking.status = BookingStatus.CANCELLED;
    } else if (role === 'mechanic' && ['active', 'completed'].includes(newStatus)) {
      booking.status = newStatus as BookingStatus;
      if (newStatus === 'active') {
        booking.assignedMechanicId = userId;
      }
    } else {
      throw new ForbiddenException('Not authorized to update booking status');
    }

    const updated = await this.bookingRepo.save(booking);

    await this.notificationsService.create({
      userId: booking.ownerId,
      title: 'Booking Updated',
      body: `Your booking #${booking.id.slice(0, 8)} is now ${newStatus}`,
      type: 'booking_update',
      referenceId: booking.id,
    });

    return updated;
  }

  async assignMechanic(id: string, mechanicId: string): Promise<Booking> {
    const booking = await this.findOne(id);
    const mechanic = await this.userRepo.findOne({
      where: { id: mechanicId },
    });
    if (!mechanic) throw new NotFoundException('Mechanic not found');

    booking.assignedMechanicId = mechanicId;
    booking.assignedMechanicName = mechanic.name;
    booking.status = BookingStatus.CONFIRMED;

    const updated = await this.bookingRepo.save(booking);

    await this.notificationsService.create({
      userId: mechanicId,
      title: 'Job Assigned',
      body: `You have been assigned a new job at ${booking.workshop?.name || 'workshop'}`,
      type: 'booking_update',
      referenceId: booking.id,
    });

    return updated;
  }
}
