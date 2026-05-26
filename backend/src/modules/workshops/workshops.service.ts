import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Workshop } from '../../database/entities/workshop.entity';
import { RedisService } from '../redis';

@Injectable()
export class WorkshopsService {
  private readonly logger = new Logger(WorkshopsService.name);

  constructor(
    @InjectRepository(Workshop)
    private readonly workshopRepo: Repository<Workshop>,
    private readonly cache: RedisService,
  ) {}

  async create(dto: {
    name: string;
    ownerId: string;
    address: string;
    city: string;
    pincode: string;
    phone?: string;
    email?: string;
    latitude?: number;
    longitude?: number;
    description?: string;
    services?: string[];
    vehicleTypes?: string[];
    openTime?: string;
    closeTime?: string;
  }): Promise<Workshop> {
    const workshop = this.workshopRepo.create({
      name: dto.name,
      ownerId: dto.ownerId,
      address: dto.address,
      city: dto.city,
      pincode: dto.pincode,
      phone: dto.phone,
      email: dto.email,
      latitude: dto.latitude,
      longitude: dto.longitude,
      description: dto.description,
      services: dto.services || [],
      vehicleTypes: dto.vehicleTypes || [],
      openTime: dto.openTime || '09:00',
      closeTime: dto.closeTime || '18:00',
    });
    const saved = await this.workshopRepo.save(workshop);

    // Invalidate list caches so new workshops appear immediately
    await this.cache.delPattern('workshops:list:*');

    return saved;
  }

  async findAll(filters: {
    city?: string;
    service?: string;
    page?: number;
    limit?: number;
    latitude?: number;
    longitude?: number;
    radiusKm?: number;
  }) {
    const { city, service, page = 1, limit = 20 } = filters;

    // Build a cache key that covers all filter dimensions
    const cacheKey = `workshops:list:${city || 'all'}:${service || 'all'}:${page}:${limit}`;

    return this.cache.getOrSet(
      cacheKey,
      async () => {
        const qb = this.workshopRepo.createQueryBuilder('workshop');

        if (city) {
          qb.where('workshop.city = :city', { city });
        }

        if (service) {
          qb.andWhere('workshop.services LIKE :service', {
            service: `%"${service}"%`,
          });
        }

        qb.orderBy('workshop.rating', 'DESC')
          .skip((page - 1) * limit)
          .take(limit);

        const [data, total] = await qb.getManyAndCount();
        return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
      },
      30, // TTL: 30 seconds for listing
    );
  }

  async findOne(id: string): Promise<Workshop> {
    return this.cache.getOrSet(
      `workshops:${id}`,
      async () => {
        const workshop = await this.workshopRepo.findOne({
          where: { id },
          relations: ['owner'],
        });
        if (!workshop) throw new NotFoundException('Workshop not found');
        return workshop;
      },
      120, // TTL: 2 minutes for individual workshop
    );
  }

  async update(
    id: string,
    userId: string,
    dto: Partial<{
      name: string;
      description: string;
      address: string;
      city: string;
      pincode: string;
      phone: string;
      email: string;
      latitude: number;
      longitude: number;
      openTime: string;
      closeTime: string;
      isOpen: boolean;
      services: string[];
      vehicleTypes: string[];
      imageUrl: string;
    }>,
  ) {
    const workshop = await this.findOne(id);
    if (workshop.ownerId !== userId) {
      throw new ForbiddenException('You can only update your own workshop');
    }
    Object.assign(workshop, dto);
    const saved = await this.workshopRepo.save(workshop);

    // Invalidate caches that may contain this workshop
    await this.cache.del(`workshops:${id}`);
    await this.cache.delPattern('workshops:list:*');

    return saved;
  }

  async findByOwner(ownerId: string) {
    return this.workshopRepo.find({
      where: { ownerId },
      order: { createdAt: 'DESC' },
    });
  }

  async getWorkshopsByCity(city: string) {
    return this.workshopRepo.find({
      where: { city, isVerified: true },
      order: { rating: 'DESC' },
      take: 50,
    });
  }

  async searchWorkshops(query: string) {
    return this.workshopRepo
      .createQueryBuilder('workshop')
      .where('workshop.name LIKE :query', { query: `%${query}%` })
      .orWhere('workshop.city LIKE :query', { query: `%${query}%` })
      .orWhere('workshop.services LIKE :query', { query: `%${query}%` })
      .andWhere('workshop.isVerified = :verified', { verified: true })
      .orderBy('workshop.rating', 'DESC')
      .limit(20)
      .getMany();
  }
}
