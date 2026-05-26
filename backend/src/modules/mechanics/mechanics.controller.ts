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
import { MechanicsService } from './mechanics.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('mechanics')
@UseGuards(AuthGuard('jwt'))
export class MechanicsController {
  constructor(private readonly mechanicsService: MechanicsService) {}

  @Get('dashboard')
  async getDashboard(@CurrentUser() user: { id: string }) {
    return this.mechanicsService.getDashboard(user.id);
  }

  @Get('job-cards')
  async getJobCards(@CurrentUser() user: { id: string }) {
    return this.mechanicsService.getJobCards(user.id);
  }

  @Post('job-cards')
  async createJobCard(
    @CurrentUser() user: { id: string },
    @Body() dto: any,
  ) {
    return this.mechanicsService.createJobCard({
      ...dto,
      mechanicId: user.id,
    });
  }

  @Patch('job-cards/:id')
  async updateJobCard(@Param('id') id: string, @Body() dto: any) {
    return this.mechanicsService.updateJobCard(id, dto);
  }

  @Get('earnings')
  async getEarnings(@CurrentUser() user: { id: string }) {
    return this.mechanicsService.getEarnings(user.id);
  }

  @Get('nearby')
  async getNearbyMechanics(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
    @Query('radius') radius?: string,
  ) {
    return this.mechanicsService.getNearbyMechanics(
      parseFloat(latitude),
      parseFloat(longitude),
      radius ? parseInt(radius) : 10,
    );
  }
}
