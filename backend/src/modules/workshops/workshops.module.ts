import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkshopsController } from './workshops.controller';
import { WorkshopsService } from './workshops.service';
import { Workshop } from '../../database/entities/workshop.entity';
import { Booking } from '../../database/entities/booking.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Workshop, Booking])],
  controllers: [WorkshopsController],
  providers: [WorkshopsService],
  exports: [WorkshopsService],
})
export class WorkshopsModule {}
