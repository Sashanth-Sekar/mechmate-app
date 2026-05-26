import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthDto, RegisterDto } from './dto/auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('firebase')
  @HttpCode(HttpStatus.OK)
  async firebaseAuth(@Body() dto: FirebaseAuthDto) {
    return this.authService.authenticateWithFirebase({
      idToken: dto.idToken,
      role: dto.role,
      displayName: dto.displayName,
      phone: dto.phone,
      avatarUrl: dto.avatarUrl,
    });
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() dto: RegisterDto) {
    return this.authService.registerWithFirebase({
      idToken: dto.idToken,
      role: dto.role,
      email: dto.email,
      displayName: dto.displayName,
      phone: dto.phone,
      avatarUrl: dto.avatarUrl,
    });
  }

  @Get('profile')
  @UseGuards(AuthGuard('jwt'))
  async getProfile(@CurrentUser() user: { id: string }) {
    return this.authService.getProfile(user.id);
  }

  @Patch('profile')
  @UseGuards(AuthGuard('jwt'))
  async updateProfile(
    @CurrentUser() user: { id: string },
    @Body() dto: { name?: string; phone?: string; avatarUrl?: string },
  ) {
    return this.authService.updateProfile(user.id, dto);
  }
}
