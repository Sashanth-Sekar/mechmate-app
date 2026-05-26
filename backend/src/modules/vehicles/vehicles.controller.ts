import { Controller, Get, Post, Put, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { VehiclesService } from './vehicles.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../../database/entities/user.entity';
import { CreateVehicleDto } from './dto/create-vehicle.dto';

@ApiTags('Vehicles')
@Controller('vehicles')
@UseGuards(AuthGuard('jwt'))
export class VehiclesController {
  constructor(private readonly vehiclesService: VehiclesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all vehicles for current user' })
  findAll(@CurrentUser() user: User) {
    return this.vehiclesService.findAll(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get vehicle by ID' })
  findById(@CurrentUser() user: User, @Param('id') id: string) {
    return this.vehiclesService.findById(id, user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Add a new vehicle' })
  create(@CurrentUser() user: User, @Body() dto: CreateVehicleDto) {
    return this.vehiclesService.create(user.id, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update vehicle' })
  update(@CurrentUser() user: User, @Param('id') id: string, @Body() dto: CreateVehicleDto) {
    return this.vehiclesService.update(id, user.id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete vehicle' })
  remove(@CurrentUser() user: User, @Param('id') id: string) {
    return this.vehiclesService.remove(id, user.id);
  }
}
