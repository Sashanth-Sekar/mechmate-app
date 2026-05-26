import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AdminService } from './admin.service';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../../database/entities/user.entity';

@Controller('admin')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  async getDashboard() {
    return this.adminService.getDashboard();
  }

  @Get('users')
  async getUsers(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getUsers(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Patch('users/:id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: { isActive?: boolean },
  ) {
    return this.adminService.updateUserStatus(id, dto);
  }

  @Get('workshops')
  async getWorkshops(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getWorkshops(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Patch('workshops/:id/verify')
  async verifyWorkshop(
    @Param('id') id: string,
    @Body() dto: { isVerified: boolean },
  ) {
    return this.adminService.verifyWorkshop(id, dto.isVerified);
  }

  @Get('bookings')
  async getBookings(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.adminService.getBookings(
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('revenue')
  async getRevenue() {
    return this.adminService.getRevenueAnalytics();
  }
}
