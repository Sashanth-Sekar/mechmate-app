import {
  Injectable,
  Logger,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

interface DecodedIdToken {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
  phone_number?: string;
  firebase: {
    sign_in_provider: string;
  };
}

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private initialized = false;
  private useEmulator = false;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    const projectId = this.configService.get<string>('app.firebase.projectId');
    const clientEmail = this.configService.get<string>('app.firebase.clientEmail');
    const privateKey = this.configService.get<string>('app.firebase.privateKey');
    const useEmulator = process.env.FIREBASE_AUTH_EMULATOR_HOST !== undefined;
    const nodeEnv = process.env.NODE_ENV || 'development';

    // Check if we should use Firebase Auth emulator (for local development)
    if (useEmulator) {
      this.logger.warn(
        '⚠️  Firebase Auth Emulator detected. Token verification will be bypassed.',
      );
      this.useEmulator = true;
      this.initialized = true;
      return;
    }

    // Check if Firebase Admin credentials are configured
    if (!clientEmail || !privateKey) {
      // In production, missing credentials should cause a startup error
      if (nodeEnv === 'production') {
        this.logger.error(
          '❌ Firebase Admin SDK is NOT configured in production! ' +
            'Set FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY environment variables. ' +
            'Authentication will be unavailable until these are set.',
        );
        this.initialized = false;
        return;
      }

      // In development, warn but allow dev-mode fallback
      this.logger.warn(
        '⚠️  Firebase Admin SDK not configured (missing FIREBASE_CLIENT_EMAIL or FIREBASE_PRIVATE_KEY).\n' +
          '   Dev mode active: Firebase ID tokens will be decoded WITHOUT verification.\n' +
          '   Set FIREBASE_AUTH_DEV_MODE=true in .env to acknowledge this.',
      );
      this.initialized = false;
      return;
    }

    try {
      // Check if already initialized
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log('✅ Firebase Admin SDK initialized successfully');
      }
      this.initialized = true;
    } catch (error) {
      this.logger.error(
        '❌ Failed to initialize Firebase Admin SDK:',
        (error as Error).message,
      );
      this.initialized = false;
    }
  }

  /**
   * Verify a Firebase ID token and return the decoded payload.
   *
   * - **Production**: Requires Firebase Admin SDK credentials. Verifies the token cryptographically.
   *   Throws UnauthorizedException if the token is invalid.
   * - **Emulator**: Decodes the JWT payload without signature verification (emulator tokens are unsigned).
   * - **Dev mode** (NODE_ENV=development + FIREBASE_AUTH_DEV_MODE=true): Decodes the JWT payload
   *   without verification. This is INSECURE and only for local development.
   * - **Misconfigured production**: Returns null, triggering an auth error upstream.
   */
  async verifyIdToken(idToken?: string): Promise<DecodedIdToken | null> {
    // If no token provided, return null (caller should handle)
    if (!idToken) {
      return null;
    }

    // If using Firebase Auth Emulator, decode without verification
    if (this.useEmulator) {
      try {
        // Emulator tokens are just JWTs that we can decode
        const parts = idToken.split('.');
        if (parts.length === 3) {
          const payload = JSON.parse(
            Buffer.from(parts[1], 'base64').toString('utf-8'),
          );
          return {
            uid: payload.sub || payload.user_id || '',
            email: payload.email,
            name: payload.name,
            phone_number: payload.phone_number,
            firebase: { sign_in_provider: payload.firebase?.sign_in_provider || 'unknown' },
          };
        }
      } catch {
        // If emulator decode fails, throw a clear error
        throw new UnauthorizedException(
          'Invalid Firebase Auth emulator token. Ensure you are using the correct emulator token format.',
        );
      }
    }

    // If Firebase Admin SDK is initialized, verify the token properly
    if (this.initialized && admin.apps.length > 0) {
      try {
        const decoded = await admin.auth().verifyIdToken(idToken);
        return {
          uid: decoded.uid,
          email: decoded.email,
          name: decoded.name,
          picture: decoded.picture,
          phone_number: decoded.phone_number,
          firebase: {
            sign_in_provider: decoded.firebase?.sign_in_provider || 'unknown',
          },
        };
      } catch (error) {
        this.logger.error(
          '❌ Firebase token verification failed:',
          (error as Error).message,
        );
        throw new UnauthorizedException('Invalid Firebase authentication token');
      }
    }

    // ============================================================
    // DEV MODE FALLBACK (INSECURE — only for local development)
    // ============================================================
    // Only enter this path when:
    //   1. NODE_ENV is NOT 'production' (i.e., 'development' or unset)
    //   2. FIREBASE_AUTH_DEV_MODE=true is explicitly set
    //
    // This prevents a production deployment with missing credentials
    // from silently falling back to insecure token decoding.
    // ============================================================
    const nodeEnv = process.env.NODE_ENV || 'development';
    const devMode = process.env.FIREBASE_AUTH_DEV_MODE === 'true';

    if (nodeEnv === 'production') {
      // Production with missing credentials — throw a clear error
      throw new UnauthorizedException(
        'Firebase authentication is unavailable. ' +
          'The server is not configured for authentication. Please contact support.',
      );
    }

    if (!devMode) {
      // Development but dev mode not explicitly enabled
      throw new UnauthorizedException(
        'Firebase Admin SDK is not configured. ' +
          'For local development, set FIREBASE_AUTH_DEV_MODE=true in your .env file ' +
          'to enable insecure token decoding, or configure Firebase Admin credentials.',
      );
    }

    this.logger.warn(
      '⚠️  DEV MODE: Firebase token decoded without verification. ' +
        'Do NOT use in production! Set FIREBASE_AUTH_DEV_MODE=false or configure ' +
        'Firebase Admin credentials for production deployments.',
    );

    try {
      const parts = idToken.split('.');
      if (parts.length !== 3) {
        throw new UnauthorizedException(
          'Invalid token format. For dev mode, provide a JWT token with ' +
            'the Firebase UID in the "sub" claim.',
        );
      }
      const payload = JSON.parse(
        Buffer.from(parts[1], 'base64').toString('utf-8'),
      );
      return {
        uid: payload.sub || payload.user_id || payload.uid || '',
        email: payload.email,
        name: payload.name,
        phone_number: payload.phone_number,
        firebase: { sign_in_provider: payload.firebase?.sign_in_provider || 'dev' },
      };
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException(
        'Invalid dev token. Provide a valid JWT with a "sub" claim containing the Firebase UID.',
      );
    }
  }

  isInitialized(): boolean {
    return this.initialized;
  }
}
