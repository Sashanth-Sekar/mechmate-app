import { TestAppContext, createTestApp } from './helpers/test-app';

describe('Bookings (e2e)', () => {
  let ctx: TestAppContext;
  let workshopId: string;
  let vehicleId: string;
  let bookingId: string;

  beforeAll(async () => {
    ctx = await createTestApp();

    // Create a workshop for booking tests
    const wsRes = await ctx.http
      .post('/api/v1/workshops')
      .set('Authorization', `Bearer ${ctx.ownerToken}`)
      .send({
        name: 'Booking Test Garage',
        address: '456 Workshop Road',
        city: 'Pune',
        pincode: '411001',
        phone: '+919876543210',
        services: ['General Service', 'Brake Repair'],
        vehicleTypes: ['Car'],
      });
    workshopId = wsRes.body.data.id;

    // Create a vehicle for booking tests
    const vRes = await ctx.http
      .post('/api/v1/vehicles')
      .set('Authorization', `Bearer ${ctx.ownerToken}`)
      .send({
        type: 'Car',
        number: 'MH14XY5678',
        make: 'Toyota',
        model: 'Corolla',
        year: 2022,
        color: 'White',
      });
    vehicleId = vRes.body.data.id;
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  // ------------------------------------------------------------------
  // Auth guard
  // ------------------------------------------------------------------
  describe('Auth guard', () => {
    it('should reject unauthenticated POST', async () => {
      await ctx.http.post('/api/v1/bookings').send({}).expect(401);
    });

    it('should reject unauthenticated GET', async () => {
      await ctx.http.get('/api/v1/bookings').expect(401);
    });

    it('should reject unauthenticated status update', async () => {
      await ctx.http
        .patch('/api/v1/bookings/some-id/status')
        .send({ status: 'confirmed' })
        .expect(401);
    });
  });

  // ------------------------------------------------------------------
  // POST /api/v1/bookings
  // ------------------------------------------------------------------
  describe('POST /api/v1/bookings', () => {
    it('should create a new booking', async () => {
      const res = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'General Service',
          vehicleId,
          bookingType: 'general',
          scheduledAt: new Date(Date.now() + 86400000).toISOString(),
          notes: 'Please check engine oil too',
        })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.workshopId).toBe(workshopId);
      expect(res.body.data.vehicleId).toBe(vehicleId);
      expect(res.body.data.ownerId).toBe(ctx.ownerUser.id);
      expect(res.body.data.service).toBe('General Service');
      expect(res.body.data.status).toBe('pending');
      expect(res.body.data.bookingType).toBe('general');
      expect(res.body.data.id).toBeDefined();

      bookingId = res.body.data.id;
    });

    it('should create an emergency booking', async () => {
      const res = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'Emergency Repair',
          vehicleId,
          bookingType: 'emergency',
          notes: 'Stranded on highway',
        })
        .expect(201);

      expect(res.body.data.bookingType).toBe('emergency');
    });

    it('should reject missing required fields', async () => {
      const res = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ workshopId: '' })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject non-existent workshop', async () => {
      const res = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId: '00000000-0000-0000-0000-000000000000',
          service: 'Test',
          vehicleId,
          bookingType: 'general',
        })
        .expect(404);

      expect(res.body.success).toBe(false);
    });

    it('should reject invalid booking type', async () => {
      const res = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'Test',
          vehicleId,
          bookingType: 'invalid_type',
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/bookings
  // ------------------------------------------------------------------
  describe('GET /api/v1/bookings', () => {
    it('should return bookings for the owner user', async () => {
      const res = await ctx.http
        .get('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should filter bookings by status', async () => {
      const res = await ctx.http
        .get('/api/v1/bookings?status=pending')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(
        res.body.data.data.every((b: any) => b.status === 'pending'),
      ).toBe(true);
    });

    it('should support pagination', async () => {
      const res = await ctx.http
        .get('/api/v1/bookings?page=1&limit=5')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.data.page).toBe(1);
      expect(res.body.data.limit).toBe(5);
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/bookings/:id
  // ------------------------------------------------------------------
  describe('GET /api/v1/bookings/:id', () => {
    it('should return booking details by ID', async () => {
      const res = await ctx.http
        .get(`/api/v1/bookings/${bookingId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(bookingId);
      expect(res.body.data.workshop).toBeDefined();
      expect(res.body.data.vehicle).toBeDefined();
      expect(res.body.data.owner).toBeDefined();
    });

    it('should return 404 for non-existent booking', async () => {
      const res = await ctx.http
        .get('/api/v1/bookings/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // PATCH /api/v1/bookings/:id/status
  // ------------------------------------------------------------------
  describe('PATCH /api/v1/bookings/:id/status', () => {
    it('should allow owner to cancel a pending booking', async () => {
      const res = await ctx.http
        .patch(`/api/v1/bookings/${bookingId}/status`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ status: 'cancelled' })
        .expect(200);

      // Response is the booking entity wrapped by the interceptor
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('cancelled');
    });

    it('should reject invalid status transition (cancelled → confirmed)', async () => {
      const res = await ctx.http
        .patch(`/api/v1/bookings/${bookingId}/status`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ status: 'confirmed' })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject owner trying to set confirmed status', async () => {
      // Create a new pending booking first
      const createRes = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'Brake Repair',
          vehicleId,
          bookingType: 'general',
        })
        .expect(201);

      const newBookingId = createRes.body.data.id;

      // Owner should NOT be able to confirm (only workshop role can)
      const res = await ctx.http
        .patch(`/api/v1/bookings/${newBookingId}/status`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ status: 'confirmed' })
        .expect(403);

      expect(res.body.success).toBe(false);
    });

    it('should reject mechanic role from confirming a booking', async () => {
      const createRes = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'General Service',
          vehicleId,
          bookingType: 'general',
        })
        .expect(201);

      const freshBookingId = createRes.body.data.id;

      // Mechanic role trying to confirm - should be 403 since they lack
      // workshop ownership privileges
      const res = await ctx.http
        .patch(`/api/v1/bookings/${freshBookingId}/status`)
        .set('Authorization', `Bearer ${ctx.mechanicToken}`)
        .send({ status: 'confirmed' })
        .expect(403);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // PATCH /api/v1/bookings/:id/assign-mechanic
  // ------------------------------------------------------------------
  describe('PATCH /api/v1/bookings/:id/assign-mechanic', () => {
    it('should assign a mechanic to a booking', async () => {
      // Create a pending booking
      const createRes = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'Engine Repair',
          vehicleId,
          bookingType: 'general',
        })
        .expect(201);

      const assignableBookingId = createRes.body.data.id;

      const res = await ctx.http
        .patch(`/api/v1/bookings/${assignableBookingId}/assign-mechanic`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ mechanicId: ctx.mechanicUser.id })
        .expect(200);

      // Response is the booking entity wrapped by the interceptor
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('confirmed');
      expect(res.body.data.assignedMechanicId).toBe(ctx.mechanicUser.id);
      expect(res.body.data.assignedMechanicName).toBe(ctx.mechanicUser.name);
    });

    it('should reject assigning a non-existent mechanic', async () => {
      const createRes = await ctx.http
        .post('/api/v1/bookings')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          workshopId,
          service: 'Oil Change',
          vehicleId,
          bookingType: 'general',
        })
        .expect(201);

      const res = await ctx.http
        .patch(`/api/v1/bookings/${createRes.body.data.id}/assign-mechanic`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          mechanicId: '00000000-0000-0000-0000-000000000000',
        })
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });
});
