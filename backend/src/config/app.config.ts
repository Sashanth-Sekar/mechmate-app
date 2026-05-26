import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '4000', 10),
  name: process.env.APP_NAME || 'MechMate',
  jwtSecret: process.env.JWT_SECRET || 'mechmate-dev-secret',
  jwtExpiration: process.env.JWT_EXPIRATION || '7d',
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || 'mechmate-production',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  },
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || '',
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },
  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL || '60', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT || '100', 10),
  },
}));
