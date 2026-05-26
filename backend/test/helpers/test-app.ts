import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { HttpExceptionFilter } from '../../src/common/filters/http-exception.filter';
import { ResponseInterceptor } from '../../src/common/interceptors/response.interceptor';
import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User, UserRole } from '../../src/database/entities/user.entity';
import { Vehicle } from '../../src/database/entities/vehicle.entity';
import { Workshop } from '../../src/database/entities/workshop.entity';
import { Booking } from '../../src/database/entities/booking.entity';
import { Notification } from '../../src/database/entities/notification.entity';
import { FirebaseService } from '../../src/modules/auth/firebase.service';

/**
 * A mock FirebaseService that always decodes the JWT payload without
 * verification. This prevents the real Firebase Admin SDK from being
 * initialized (which would fail on fake test tokens).
 */
class MockFirebaseService {
  async verifyIdToken(idToken?: string): Promise<{
    uid: string;
    email?: string;
    name?: string;
    picture?: string;
    phone_number?: string;
    firebase: { sign_in_provider: string };
  } | null> {
    if (!idToken) return null;
    try {
      const parts = idToken.split('.');
      if (parts.length !== 3) return null;
      const payload = JSON.parse(
        Buffer.from(parts[1], 'base64').toString('utf-8'),
      );
      return {
        uid: payload.sub || payload.user_id || payload.uid || '',
        email: payload.email,
        name: payload.name,
        phone_number: payload.phone_number,
        firebase: {
          sign_in_provider: payload.firebase?.sign_in_provider || 'dev',
        },
      };
    } catch {
      return null;
    }
  }

  isInitialized(): boolean {
    return false;
  }
}

/** Set up environment variables for test database before any module is loaded. */
function setTestEnv(): void {
  process.env.DATABASE_TYPE = 'better-sqlite3';
  process.env.DATABASE_DATABASE = ':memory:';
  process.env.DATABASE_SYNCHRONIZE = 'true';
  process.env.NODE_ENV = 'development';
  process.env.FIREBASE_AUTH_DEV_MODE = 'true';
  process.env.JWT_SECRET = 'mechmate-test-secret';

  // Clear Firebase Admin credentials so the real FirebaseService
  // doesn't try to initialise Firebase Admin SDK with .env values.
  // Instead we replace the provider with MockFirebaseService below.
  process.env.FIREBASE_PROJECT_ID = '';
  process.env.FIREBASE_CLIENT_EMAIL = '';
  process.env.FIREBASE_PRIVATE_KEY = '';
}

export interface TestAppContext {
  app: INestApplication;
  jwtService: JwtService;
  userRepo: Repository<User>;
  vehicleRepo: Repository<Vehicle>;
  workshopRepo: Repository<Workshop>;
  bookingRepo: Repository<Booking>;
  notificationRepo: Repository<Notification>;
  /** JWT for the owner test user (Bearer token value). */
  ownerToken: string;
  /** JWT for the mechanic test user (Bearer token value). */
  mechanicToken: string;
  /** Owner test user entity. */
  ownerUser: User;
  /** Mechanic test user entity. */
  mechanicUser: User;
  /** Super-test helper bound to the app. */
  http: request.SuperTest<request.Test>;
}

/**
 * Create a fully-initialized NestJS application backed by an in-memory SQLite
 * database, with two pre-seeded users (owner + mechanic) and their JWTs.
 *
 * Call `await app.close()` in `afterAll` to clean up.
 */
export async function createTestApp(): Promise<TestAppContext> {
  setTestEnv();

  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(FirebaseService)
    .useClass(MockFirebaseService)
    .compile();

  const app = moduleFixture.createNestApplication();

  // Apply the same global configuration as main.ts
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());

  await app.init();

  const http = request(app.getHttpServer()) as unknown as request.SuperTest<request.Test>;

  // Resolve repositories and services
  const jwtService = app.get(JwtService);
  const userRepo = app.get<Repository<User>>(getRepositoryToken(User));
  const vehicleRepo = app.get<Repository<Vehicle>>(getRepositoryToken(Vehicle));
  const workshopRepo = app.get<Repository<Workshop>>(getRepositoryToken(Workshop));
  const bookingRepo = app.get<Repository<Booking>>(getRepositoryToken(Booking));
  const notificationRepo = app.get<Repository<Notification>>(getRepositoryToken(Notification));

  // Seed test users
  const ownerUser = await userRepo.save({
    firebaseUid: 'test-owner-uid',
    name: 'Test Owner',
    email: 'owner@test.com',
    phone: '+1234567890',
    role: UserRole.OWNER,
    isActive: true,
  });

  const mechanicUser = await userRepo.save({
    firebaseUid: 'test-mechanic-uid',
    name: 'Test Mechanic',
    email: 'mechanic@test.com',
    phone: '+1234567891',
    role: UserRole.MECHANIC,
    isActive: true,
  });

  // Generate valid JWTs (signed with the app's JwtService, so the
  // JwtStrategy can validate them correctly).
  const ownerToken = jwtService.sign({
    sub: ownerUser.id,
    role: ownerUser.role,
    email: ownerUser.email,
  });
  const mechanicToken = jwtService.sign({
    sub: mechanicUser.id,
    role: mechanicUser.role,
    email: mechanicUser.email,
  });

  return {
    app,
    jwtService,
    userRepo,
    vehicleRepo,
    bookingRepo,
    notificationRepo,
    workshopRepo,
    ownerToken,
    mechanicToken,
    ownerUser,
    mechanicUser,
    http,
  };
}

/**
 * Build a fake Firebase ID token for use in dev-mode auth tests.
 * The mock FirebaseService decodes the JWT payload without verifying
 * the signature, so the signature can be a dummy value.
 */
export function createDevIdToken(
  uid: string,
  email?: string,
  name?: string,
): string {
  const header = Buffer.from(
    JSON.stringify({ alg: 'HS256', typ: 'JWT' }),
  ).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({ sub: uid, email, name }),
  ).toString('base64url');
  return `${header}.${payload}.dummy-signature`;
}
