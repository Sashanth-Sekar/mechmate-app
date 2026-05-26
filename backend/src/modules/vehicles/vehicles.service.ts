import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vehicle } from '../../database/entities/vehicle.entity';
import { CreateVehicleDto } from './dto/create-vehicle.dto';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectRepository(Vehicle)
    private vehicleRepository: Repository<Vehicle>,
  ) {}

  async findAll(ownerId: string): Promise<Vehicle[]> {
    return this.vehicleRepository.find({
      where: { ownerId },
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string, ownerId?: string): Promise<Vehicle> {
    const vehicle = await this.vehicleRepository.findOne({ where: { id } });
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    if (ownerId && vehicle.ownerId !== ownerId) {
      throw new NotFoundException('Vehicle not found');
    }
    return vehicle;
  }

  async create(ownerId: string, dto: CreateVehicleDto): Promise<Vehicle> {
    const vehicle = this.vehicleRepository.create({
      ...dto,
      ownerId,
    });
    return this.vehicleRepository.save(vehicle);
  }

  async update(id: string, ownerId: string, dto: Partial<CreateVehicleDto>): Promise<Vehicle> {
    const vehicle = await this.findById(id);
    if (vehicle.ownerId !== ownerId) throw new NotFoundException('Vehicle not found');
    Object.assign(vehicle, dto);
    return this.vehicleRepository.save(vehicle);
  }

  async remove(id: string, ownerId: string): Promise<void> {
    const vehicle = await this.findById(id);
    if (vehicle.ownerId !== ownerId) throw new NotFoundException('Vehicle not found');
    await this.vehicleRepository.remove(vehicle);
  }
}
