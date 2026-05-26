import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get('categories')
  async getCategories() {
    return this.servicesService.getServiceCategories();
  }

  @Get('available')
  async getAvailable(@Param('workshopId') workshopId?: string) {
    return this.servicesService.getAvailableServices(workshopId);
  }

  @Put('workshop/:workshopId')
  @UseGuards(AuthGuard('jwt'))
  async updateWorkshopServices(
    @Param('workshopId') workshopId: string,
    @Body() dto: { services: string[] },
  ) {
    return this.servicesService.updateWorkshopServices(
      workshopId,
      dto.services,
    );
  }
}
