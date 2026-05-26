import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MechanicsService } from './mechanics.service';
import { MechanicsController } from './mechanics.controller';
import { User } from '../../database/entities/user.entity';
import { JobCard } from '../../database/entities/job-card.entity';
import { Workshop } from '../../database/entities/workshop.entity';
import { Booking } from '../../database/entities/booking.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, JobCard, Workshop, Booking]),
  ],
  controllers: [MechanicsController],
  providers: [MechanicsService],
  exports: [MechanicsService],
})
export class MechanicsModule {}
