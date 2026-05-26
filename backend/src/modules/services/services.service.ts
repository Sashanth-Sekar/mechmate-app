import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Workshop } from '../../database/entities/workshop.entity';

@Injectable()
export class ServicesService {
  constructor(
    @InjectRepository(Workshop)
    private readonly workshopRepo: Repository<Workshop>,
  ) {}

  // Standard service categories that workshops can offer
  static readonly SERVICE_CATEGORIES = [
    'general_service',
    'engine_repair',
    'brake_service',
    'tire_service',
    'battery_service',
    'ac_service',
    'electrical_repair',
    'body_repair',
    'paint_service',
    'transmission_repair',
    'suspension_repair',
    'exhaust_service',
    'oil_change',
    'wheel_alignment',
    'diagnostics',
    'roadside_assistance',
    'doorstep_service',
    'pickup_drop',
  ];

  async getAvailableServices(workshopId?: string) {
    if (workshopId) {
      const workshop = await this.workshopRepo.findOne({
        where: { id: workshopId },
      });
      if (!workshop) throw new NotFoundException('Workshop not found');
      return {
        categories: ServicesService.SERVICE_CATEGORIES,
        workshopServices: workshop.services || [],
      };
    }

    return { categories: ServicesService.SERVICE_CATEGORIES };
  }

  async updateWorkshopServices(
    workshopId: string,
    services: string[],
  ) {
    const workshop = await this.workshopRepo.findOne({
      where: { id: workshopId },
    });
    if (!workshop) throw new NotFoundException('Workshop not found');
    workshop.services = services;
    return this.workshopRepo.save(workshop);
  }

  async getServiceCategories() {
    return ServicesService.SERVICE_CATEGORIES;
  }
}
