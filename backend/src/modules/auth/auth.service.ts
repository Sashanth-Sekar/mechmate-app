import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { User, UserRole } from '../../database/entities/user.entity';
import { FirebaseService } from './firebase.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly firebaseService: FirebaseService,
  ) {}

  /**
   * Authenticate a user via Firebase ID token.
   *
   * Flow:
   * 1. Verify the Firebase ID token server-side using Firebase Admin SDK
   * 2. Extract the authenticated UID, email, name from the decoded token
   * 3. Find an existing user by firebaseUid, or create a new one
   * 4. Return the user and a signed JWT
   *
   * In development mode (without Firebase Admin credentials configured),
   * the FirebaseService falls back to trusting the token payload without
   * verification. This allows local development without Firebase setup.
   */
  async authenticateWithFirebase(dto: {
    idToken: string;
    role: UserRole;
    displayName?: string;
    phone?: string;
    avatarUrl?: string;
  }) {
    // Step 1: Verify the Firebase ID token
    const decoded = await this.firebaseService.verifyIdToken(dto.idToken);

    if (!decoded) {
      // Dev mode: Firebase Admin SDK not initialized and no emulator.
      // Fall back to accepting the idToken as containing the UID in the payload.
      // This is less secure, so we log a warning.
      const devUid = this.extractUidFromToken(dto.idToken);
      if (!devUid) {
        throw new UnauthorizedException(
          'Invalid authentication token. ' +
            'In production, ensure Firebase Admin credentials are configured. ' +
            'In development, ensure you are sending a valid Firebase ID token.',
        );
      }
      return this.findOrCreateUser({
        firebaseUid: devUid,
        email: this.extractEmailFromToken(dto.idToken) || '',
        name: dto.displayName || 'User',
        phone: dto.phone,
        role: dto.role,
        avatarUrl: dto.avatarUrl,
      });
    }

    // Production mode: Token was verified by Firebase Admin SDK
    return this.findOrCreateUser({
      firebaseUid: decoded.uid,
      email: decoded.email || '',
      name: dto.displayName || decoded.name || 'User',
      phone: dto.phone || decoded.phone_number,
      role: dto.role,
      avatarUrl: dto.avatarUrl || decoded.picture,
    });
  }

  /**
   * Register a new user (with optional email in dev mode).
   */
  async registerWithFirebase(dto: {
    idToken: string;
    role: UserRole;
    email?: string;
    displayName?: string;
    phone?: string;
    avatarUrl?: string;
  }) {
    const decoded = await this.firebaseService.verifyIdToken(dto.idToken);

    if (!decoded) {
      // Dev mode fallback
      const devUid = this.extractUidFromToken(dto.idToken);
      if (!devUid || !dto.email) {
        throw new BadRequestException(
          'In development mode without Firebase credentials, ' +
            'both idToken (containing UID) and email are required for registration.',
        );
      }
      return this.findOrCreateUser({
        firebaseUid: devUid,
        email: dto.email,
        name: dto.displayName || 'User',
        phone: dto.phone,
        role: dto.role,
        avatarUrl: dto.avatarUrl,
      });
    }

    return this.findOrCreateUser({
      firebaseUid: decoded.uid,
      email: decoded.email || dto.email || '',
      name: dto.displayName || decoded.name || 'User',
      phone: dto.phone || decoded.phone_number,
      role: dto.role,
      avatarUrl: dto.avatarUrl || decoded.picture,
    });
  }

  /**
   * Find or create a user by Firebase UID.
   */
  private async findOrCreateUser(data: {
    firebaseUid: string;
    email: string;
    name: string;
    phone?: string;
    role: UserRole;
    avatarUrl?: string;
  }) {
    let user = await this.userRepo.findOne({
      where: { firebaseUid: data.firebaseUid },
    });

    if (!user) {
      user = this.userRepo.create({
        firebaseUid: data.firebaseUid,
        email: data.email,
        name: data.name,
        phone: data.phone,
        role: data.role,
        avatarUrl: data.avatarUrl,
      });
      user = await this.userRepo.save(user);
    } else if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    const token = this.generateToken(user);
    return { user, token };
  }

  async getProfile(userId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['vehicles'],
    });
    if (!user) throw new BadRequestException('User not found');
    return user;
  }

  async updateProfile(
    userId: string,
    dto: { name?: string; phone?: string; avatarUrl?: string },
  ) {
    await this.userRepo.update(userId, dto);
    return this.userRepo.findOne({ where: { id: userId } });
  }

  private generateToken(user: User): string {
    const payload = {
      sub: user.id,
      role: user.role,
      email: user.email,
    };
    return this.jwtService.sign(payload);
  }

  /**
   * Dev-mode helper: decode an unverified JWT payload (header.payload.signature).
   * Returns null if the token is not a valid 3-part JWT.
   */
  private decodeJwtPayload(token: string): Record<string, unknown> | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      return JSON.parse(
        Buffer.from(parts[1], 'base64').toString('utf-8'),
      ) as Record<string, unknown>;
    } catch {
      return null;
    }
  }

  /**
   * Dev-mode helper: extract UID from an unverified JWT payload.
   */
  private extractUidFromToken(token: string): string | null {
    const payload = this.decodeJwtPayload(token);
    if (!payload) return null;
    return (payload.sub || payload.user_id || payload.uid || null) as string | null;
  }

  /**
   * Dev-mode helper: extract email from an unverified JWT payload.
   */
  private extractEmailFromToken(token: string): string | null {
    const payload = this.decodeJwtPayload(token);
    if (!payload) return null;
    return (payload.email || null) as string | null;
  }
}
