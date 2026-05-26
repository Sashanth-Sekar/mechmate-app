import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { BookingsService } from './bookings.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';

@Controller('bookings')
@UseGuards(AuthGuard('jwt'))
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  async create(
    @CurrentUser() user: { id: string; role: string },
    @Body() dto: CreateBookingDto,
  ) {
    return this.bookingsService.create(user.id, dto);
  }

  @Get()
  async findAll(
    @CurrentUser() user: { id: string; role: string },
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.bookingsService.findAll(user.id, user.role, {
      status,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }

  @Patch(':id/status')
  async updateStatus(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
    @Body() dto: UpdateBookingStatusDto,
  ) {
    return this.bookingsService.updateStatus(id, user.id, user.role, dto.status);
  }

  @Patch(':id/assign-mechanic')
  async assignMechanic(
    @Param('id') id: string,
    @Body() dto: { mechanicId: string },
  ) {
    return this.bookingsService.assignMechanic(id, dto.mechanicId);
  }
}
