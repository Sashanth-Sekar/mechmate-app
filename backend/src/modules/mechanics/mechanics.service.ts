import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from '../../database/entities/user.entity';
import { JobCard } from '../../database/entities/job-card.entity';
import { Booking, BookingStatus } from '../../database/entities/booking.entity';
import { Workshop } from '../../database/entities/workshop.entity';

@Injectable()
export class MechanicsService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(JobCard)
    private readonly jobCardRepo: Repository<JobCard>,
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Workshop)
    private readonly workshopRepo: Repository<Workshop>,
  ) {}

  async getDashboard(mechanicId: string) {
    const mechanic = await this.userRepo.findOne({
      where: { id: mechanicId },
    });
    if (!mechanic) throw new Error('Mechanic not found');

    const assignedBookings = await this.bookingRepo.find({
      where: { assignedMechanicId: mechanicId, status: BookingStatus.CONFIRMED },
      take: 20,
      order: { createdAt: 'DESC' },
    });

    const activeJobs = await this.jobCardRepo.find({
      where: { mechanicId, status: 'active' },
      take: 10,
      order: { createdAt: 'DESC' },
    });

    const completedJobs = await this.jobCardRepo.find({
      where: { mechanicId, status: 'completed' },
      take: 50,
    });

    const totalEarnings = completedJobs.reduce(
      (sum, job) => sum + job.laborCharges,
      0,
    );

    return {
      mechanic: {
        id: mechanic.id,
        name: mechanic.name,
        email: mechanic.email,
        phone: mechanic.phone,
        role: mechanic.role,
      },
      stats: {
        assignedJobs: assignedBookings.length,
        activeJobs: activeJobs.length,
        completedJobs: completedJobs.length,
        totalEarnings,
      },
      assignedBookings,
      activeJobs,
    };
  }

  async getJobCards(mechanicId: string) {
    return this.jobCardRepo.find({
      where: { mechanicId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async createJobCard(dto: {
    bookingId: string;
    workshopId: string;
    mechanicId: string;
    customerName: string;
    vehicleType: string;
    vehicleNumber: string;
    vehicleMake: string;
    vehicleModel: string;
    service: string;
    partsUsed?: string[];
    labourNotes?: string;
    laborCharges?: number;
  }) {
    const booking = await this.bookingRepo.findOne({
      where: { id: dto.bookingId },
    });
    if (!booking) throw new Error('Booking not found');

    const jobCard = this.jobCardRepo.create({
      bookingId: dto.bookingId,
      workshopId: dto.workshopId,
      mechanicId: dto.mechanicId,
      customerName: dto.customerName,
      vehicleType: dto.vehicleType,
      vehicleNumber: dto.vehicleNumber,
      vehicleMake: dto.vehicleMake,
      vehicleModel: dto.vehicleModel,
      service: dto.service,
      partsUsed: dto.partsUsed || [],
      labourNotes: dto.labourNotes,
      laborCharges: dto.laborCharges || 0,
      status: 'active',
    });

    return this.jobCardRepo.save(jobCard);
  }

  async updateJobCard(
    jobCardId: string,
    dto: {
      status?: 'active' | 'completed';
      partsUsed?: string[];
      labourNotes?: string;
      laborCharges?: number;
    },
  ) {
    const jobCard = await this.jobCardRepo.findOne({
      where: { id: jobCardId },
    });
    if (!jobCard) throw new Error('Job card not found');

    if (dto.status) jobCard.status = dto.status;
    if (dto.partsUsed) jobCard.partsUsed = dto.partsUsed;
    if (dto.labourNotes !== undefined) jobCard.labourNotes = dto.labourNotes;
    if (dto.laborCharges !== undefined) jobCard.laborCharges = dto.laborCharges;

    if (dto.status === 'completed') {
      jobCard.completedAt = new Date();
    }

    const saved = await this.jobCardRepo.save(jobCard);

    if (dto.status === 'completed') {
      await this.bookingRepo.update(
        { id: jobCard.bookingId },
        { status: BookingStatus.COMPLETED, isPaid: true },
      );
    }

    return saved;
  }

  async getEarnings(mechanicId: string) {
    const completedJobs = await this.jobCardRepo.find({
      where: { mechanicId, status: 'completed' },
      order: { completedAt: 'DESC' },
      take: 100,
    });

    const totalEarnings = completedJobs.reduce(
      (sum, job) => sum + job.laborCharges,
      0,
    );

    const monthlyEarnings: Record<string, number> = {};
    completedJobs.forEach((job) => {
      if (job.completedAt) {
        const key = `${job.completedAt.getFullYear()}-${String(job.completedAt.getMonth() + 1).padStart(2, '0')}`;
        monthlyEarnings[key] =
          (monthlyEarnings[key] || 0) + job.laborCharges;
      }
    });

    return {
      totalEarnings,
      totalJobs: completedJobs.length,
      monthlyEarnings: Object.entries(monthlyEarnings).map(([month, amount]) => ({
        month,
        amount,
      })),
      recentJobs: completedJobs.slice(0, 10),
    };
  }

  async getNearbyMechanics(latitude: number, longitude: number, radiusKm = 10) {
    const latDelta = radiusKm / 111.0;
    const lonDelta = radiusKm / (111.0 * Math.cos((latitude * Math.PI) / 180));

    return this.userRepo
      .createQueryBuilder('user')
      .where('user.role = :role', { role: UserRole.MECHANIC })
      .andWhere('user.isActive = :active', { active: true })
      .limit(50)
      .getMany();
  }
}
