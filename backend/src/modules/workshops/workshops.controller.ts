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
import { WorkshopsService } from './workshops.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateWorkshopDto } from './dto/create-workshop.dto';

@Controller('workshops')
export class WorkshopsController {
  constructor(private readonly workshopsService: WorkshopsService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  async create(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateWorkshopDto,
  ) {
    return this.workshopsService.create({ ...dto, ownerId: user.id });
  }

  @Get()
  async findAll(
    @Query('city') city?: string,
    @Query('service') service?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.workshopsService.findAll({
      city,
      service,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('search')
  async search(@Query('q') query: string) {
    return this.workshopsService.searchWorkshops(query);
  }

  @Get('my-workshops')
  @UseGuards(AuthGuard('jwt'))
  async getMyWorkshops(@CurrentUser() user: { id: string }) {
    return this.workshopsService.findByOwner(user.id);
  }

  @Get('city/:city')
  async getByCity(@Param('city') city: string) {
    return this.workshopsService.getWorkshopsByCity(city);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.workshopsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(AuthGuard('jwt'))
  async update(
    @Param('id') id: string,
    @CurrentUser() user: { id: string },
    @Body() dto: any,
  ) {
    return this.workshopsService.update(id, user.id, dto);
  }
}
