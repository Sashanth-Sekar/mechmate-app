import {
  IsString,
  IsOptional,
  IsDateString,
  IsEnum,
  IsNumber,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookingType } from '../../../database/entities/booking.entity';

export class CreateBookingDto {
  @ApiProperty()
  @IsString()
  workshopId: string;

  @ApiProperty()
  @IsString()
  service: string;

  @ApiProperty()
  @IsString()
  vehicleId: string;

  @ApiProperty({ enum: BookingType })
  @IsEnum(BookingType)
  bookingType: BookingType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  pickupLatitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  pickupLongitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  pickupAddress?: string;
}
