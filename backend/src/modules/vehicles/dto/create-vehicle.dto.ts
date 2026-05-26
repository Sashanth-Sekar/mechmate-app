import { IsString, IsNumber, IsOptional, Min, Max, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateVehicleDto {
  @ApiProperty({ example: 'Car', enum: ['Car', 'Bike'] })
  @IsString()
  type: string;

  @ApiProperty({ example: 'MH12AB1234' })
  @IsString()
  @MinLength(1)
  number: string;

  @ApiProperty({ example: 'Honda' })
  @IsString()
  make: string;

  @ApiProperty({ example: 'City' })
  @IsString()
  model: string;

  @ApiProperty({ example: 2021 })
  @IsNumber()
  @Min(1990)
  @Max(2030)
  year: number;

  @ApiPropertyOptional({ example: 'Red' })
  @IsString()
  @IsOptional()
  color?: string;

  @ApiPropertyOptional({ example: 'Petrol' })
  @IsString()
  @IsOptional()
  fuelType?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  registrationNumber?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  odometerReading?: number;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  insuranceDetails?: string;
}
