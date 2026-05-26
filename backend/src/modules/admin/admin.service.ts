import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from '../../database/entities/user.entity';
import { Workshop } from '../../database/entities/workshop.entity';
import { Booking, BookingStatus } from '../../database/entities/booking.entity';
import { Payment, PaymentStatus } from '../../database/entities/payment.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Workshop)
    private readonly workshopRepo: Repository<Workshop>,
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Payment)
    private readonly paymentRepo: Repository<Payment>,
  ) {}

  async getDashboard() {
    const [
      totalUsers,
      totalWorkshops,
      totalMechanics,
      totalBookings,
      totalRevenue,
      recentBookings,
      pendingWorkshops,
    ] = await Promise.all([
      this.userRepo.count(),
      this.workshopRepo.count(),
      this.userRepo.count({ where: { role: UserRole.MECHANIC } }),
      this.bookingRepo.count(),
      this.getTotalRevenue(),
      this.bookingRepo.find({
        order: { createdAt: 'DESC' },
        take: 10,
        relations: ['owner', 'workshop'],
      }),
      this.workshopRepo.count({ where: { isVerified: false } }),
    ]);

    return {
      stats: {
        totalUsers,
        totalWorkshops,
        totalMechanics,
        totalBookings,
        totalRevenue,
        pendingWorkshops,
      },
      recentBookings,
    };
  }

  private async getTotalRevenue(): Promise<number> {
    const result = await this.paymentRepo
      .createQueryBuilder('payment')
      .select('SUM(payment.amount)', 'total')
      .where('payment.status = :status', { status: PaymentStatus.SUCCESS })
      .getRawOne();
    return parseFloat(result?.total || '0');
  }

  async getUsers(page = 1, limit = 20) {
    const [data, total] = await this.userRepo.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateUserStatus(userId: string, dto: { isActive?: boolean }) {
    await this.userRepo.update(userId, { isActive: dto.isActive });
    return this.userRepo.findOne({ where: { id: userId } });
  }

  async getWorkshops(page = 1, limit = 20) {
    const [data, total] = await this.workshopRepo.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
      relations: ['owner'],
    });
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async verifyWorkshop(workshopId: string, isVerified: boolean) {
    await this.workshopRepo.update(workshopId, { isVerified });
    return this.workshopRepo.findOne({ where: { id: workshopId } });
  }

  async getBookings(page = 1, limit = 20) {
    const [data, total] = await this.bookingRepo.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
      relations: ['owner', 'workshop'],
    });
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getRevenueAnalytics() {
    const payments = await this.paymentRepo.find({
      where: { status: PaymentStatus.SUCCESS },
      order: { createdAt: 'DESC' },
    });

    const monthlyData: Record<string, number> = {};
    payments.forEach((p) => {
      const key = `${p.createdAt.getFullYear()}-${String(p.createdAt.getMonth() + 1).padStart(2, '0')}`;
      monthlyData[key] = (monthlyData[key] || 0) + p.amount;
    });

    const totalRevenue = payments.reduce((sum, p) => sum + p.amount, 0);
    const totalTransactions = payments.length;

    return {
      totalRevenue,
      totalTransactions,
      monthlyData: Object.entries(monthlyData).map(([month, amount]) => ({
        month,
        amount,
      })),
    };
  }
}
