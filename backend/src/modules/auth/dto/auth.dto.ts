import { IsString, IsNotEmpty, IsEmail, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../../database/entities/user.entity';

export class FirebaseAuthDto {
  @ApiProperty({
    description:
      'Firebase ID token from the client SDK. The server verifies this token ' +
      'using Firebase Admin SDK to extract the authenticated UID and profile info.',
  })
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @ApiProperty({ enum: UserRole })
  @IsEnum(UserRole)
  role: UserRole;

  @ApiPropertyOptional({
    description:
      'Optional display name. If not provided, the name from the Firebase profile is used.',
  })
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}

export class RegisterDto {
  @ApiProperty({
    description:
      'Firebase ID token from the client SDK. The server verifies this token ' +
      'using Firebase Admin SDK to extract the authenticated UID and profile info.',
  })
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @ApiProperty({ enum: UserRole })
  @IsEnum(UserRole)
  role: UserRole;

  @ApiPropertyOptional({
    description:
      'Optional email for registration. In dev mode without Firebase credentials, ' +
      'this is required. In production, it is extracted from the verified token.',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  displayName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  avatarUrl?: string;
}
