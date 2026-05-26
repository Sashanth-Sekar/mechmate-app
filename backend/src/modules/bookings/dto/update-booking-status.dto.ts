import { IsString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateBookingStatusDto {
  @ApiProperty({ enum: ['confirmed', 'active', 'completed', 'cancelled'] })
  @IsEnum(['confirmed', 'active', 'completed', 'cancelled'])
  status: string;
}
