import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { User, UserRole } from './entities/user.entity';
import { Workshop } from './entities/workshop.entity';

/**
 * Generate a dev-mode JWT token that can be used with the /api/v1/auth/firebase
 * endpoint when FIREBASE_AUTH_DEV_MODE=true and Firebase Admin credentials are
 * not configured.
 *
 * The token is a signed JWT with the firebaseUid in the "sub" claim, mimicking
 * the format of a Firebase ID token. The FirebaseService verifies it by decoding
 * the JWT payload (no signature verification in dev mode).
 */
function generateDevToken(
  jwtService: JwtService,
  firebaseUid: string,
  email: string,
  name: string,
): string {
  // Sign a JWT that mimics a Firebase ID token payload
  return jwtService.sign(
    {
      sub: firebaseUid,
      email,
      name,
      firebase: { sign_in_provider: 'password' },
    },
    { expiresIn: '365d' },
  );
}

async function seed() {
  const app = await NestFactory.createApplicationContext(AppModule);

  const userRepo = app.get(getRepositoryToken(User));
  const workshopRepo = app.get(getRepositoryToken(Workshop));
  const jwtService = app.get(JwtService);

  console.log('🌱 Seeding database...');
  console.log('');

  // Create admin user
  const admin = userRepo.create({
    firebaseUid: 'firebase_admin_uid',
    name: 'MechMate Admin',
    email: 'admin@mechmate.com',
    phone: '+911234567890',
    role: UserRole.ADMIN,
    isActive: true,
  });
  await userRepo.save(admin);
  console.log('✅ Admin user created');

  // Create sample owner
  const owner = userRepo.create({
    firebaseUid: 'firebase_owner_uid',
    name: 'Rahul Sharma',
    email: 'owner@example.com',
    phone: '+919876543210',
    role: UserRole.OWNER,
    isActive: true,
  });
  await userRepo.save(owner);
  console.log('✅ Sample owner created');

  // Create sample workshop owner
  const workshopOwner = userRepo.create({
    firebaseUid: 'firebase_workshop_uid',
    name: 'Premium Auto Garage',
    email: 'workshop@example.com',
    phone: '+919876543211',
    role: UserRole.WORKSHOP,
    isActive: true,
  });
  await userRepo.save(workshopOwner);

  // Create sample workshop
  const workshop = workshopRepo.create({
    name: 'Premium Auto Garage & Service Center',
    ownerId: workshopOwner.id,
    description: 'Your trusted partner for all automobile service needs. We specialize in luxury and premium vehicles.',
    phone: '+919876543211',
    email: 'workshop@example.com',
    address: '123, Automotive Street, Sector 62',
    city: 'Noida',
    pincode: '201301',
    services: [
      'general_service', 'engine_repair', 'brake_service',
      'tire_service', 'battery_service', 'ac_service',
      'oil_change', 'diagnostics',
    ],
    vehicleTypes: ['sedan', 'suv', 'hatchback', 'luxury'],
    openTime: '09:00',
    closeTime: '19:00',
    isOpen: true,
    isVerified: true,
    rating: 4.5,
    reviewCount: 128,
    country: 'India',
    countryCode: 'IN',
    state: 'Uttar Pradesh',
    stateCode: 'UP',
    latitude: 28.6139,
    longitude: 77.2090,
  });
  await workshopRepo.save(workshop);
  console.log('✅ Sample workshop created');

  // Create sample mechanic
  const mechanic = userRepo.create({
    firebaseUid: 'firebase_mechanic_uid',
    name: 'Vikram Singh',
    email: 'mechanic@example.com',
    phone: '+919876543212',
    role: UserRole.MECHANIC,
    isActive: true,
  });
  await userRepo.save(mechanic);
  console.log('✅ Sample mechanic created');

  // Generate dev-mode JWT tokens for each test account
  const adminToken = generateDevToken(
    jwtService,
    'firebase_admin_uid',
    'admin@mechmate.com',
    'MechMate Admin',
  );
  const ownerToken = generateDevToken(
    jwtService,
    'firebase_owner_uid',
    'owner@example.com',
    'Rahul Sharma',
  );
  const workshopToken = generateDevToken(
    jwtService,
    'firebase_workshop_uid',
    'workshop@example.com',
    'Premium Auto Garage',
  );
  const mechanicToken = generateDevToken(
    jwtService,
    'firebase_mechanic_uid',
    'mechanic@example.com',
    'Vikram Singh',
  );

  console.log('');
  console.log('🎉 Seeding complete!');
  console.log('');
  console.log('===========================================');
  console.log('  📋 DEV AUTH TOKENS (FIREBASE_AUTH_DEV_MODE)');
  console.log('===========================================');
  console.log('');
  console.log('Use these tokens with POST /api/v1/auth/firebase');
  console.log('');
  console.log('Admin (role: admin):');
  console.log(`  ${adminToken}`);
  console.log('');
  console.log('Owner (role: owner):');
  console.log(`  ${ownerToken}`);
  console.log('');
  console.log('Workshop (role: workshop):');
  console.log(`  ${workshopToken}`);
  console.log('');
  console.log('Mechanic (role: mechanic):');
  console.log(`  ${mechanicToken}`);
  console.log('');
  console.log('===========================================');
  console.log('');
  console.log('curl example:');
  console.log('  curl -X POST http://localhost:4000/api/v1/auth/firebase \\');
  console.log('    -H "Content-Type: application/json" \\');
  console.log(`    -d '{"idToken":"${adminToken.substring(0, 40)}...","role":"admin"}'`);
  console.log('');

  await app.close();
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
