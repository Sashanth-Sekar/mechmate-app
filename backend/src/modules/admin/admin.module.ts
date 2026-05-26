import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { User } from '../../database/entities/user.entity';
import { Workshop } from '../../database/entities/workshop.entity';
import { Booking } from '../../database/entities/booking.entity';
import { Payment } from '../../database/entities/payment.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Workshop, Booking, Payment]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
