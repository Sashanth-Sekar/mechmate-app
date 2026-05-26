import { TestAppContext, createTestApp } from './helpers/test-app';

describe('Vehicles (e2e)', () => {
  let ctx: TestAppContext;

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  // ------------------------------------------------------------------
  // Auth guard
  // ------------------------------------------------------------------
  describe('Auth guard', () => {
    it('should reject unauthenticated GET', async () => {
      await ctx.http.get('/api/v1/vehicles').expect(401);
    });

    it('should reject unauthenticated POST', async () => {
      await ctx.http.post('/api/v1/vehicles').send({}).expect(401);
    });

    it('should reject unauthenticated DELETE', async () => {
      await ctx.http.delete('/api/v1/vehicles/some-id').expect(401);
    });
  });

  // ------------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------------
  let createdVehicleId: string;

  describe('POST /api/v1/vehicles', () => {
    it('should create a new vehicle', async () => {
      const res = await ctx.http
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          type: 'Car',
          number: 'MH12AB1234',
          make: 'Honda',
          model: 'City',
          year: 2021,
          color: 'Red',
          fuelType: 'Petrol',
        })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.type).toBe('Car');
      expect(res.body.data.number).toBe('MH12AB1234');
      expect(res.body.data.make).toBe('Honda');
      expect(res.body.data.model).toBe('City');
      expect(res.body.data.year).toBe(2021);
      expect(res.body.data.ownerId).toBe(ctx.ownerUser.id);
      expect(res.body.data.id).toBeDefined();

      createdVehicleId = res.body.data.id;
    });

    it('should reject empty required fields', async () => {
      const res = await ctx.http
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          type: 'Car',
          number: '',
          make: '',
          model: '',
          year: 2021,
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject year out of range', async () => {
      const res = await ctx.http
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          type: 'Car',
          number: 'TEST1234',
          make: 'Test',
          model: 'Test',
          year: 1980, // below Min(1990)
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject extra fields not in the DTO (forbidNonWhitelisted)', async () => {
      const res = await ctx.http
        .post('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          type: 'Car',
          number: 'TEST5678',
          make: 'Test',
          model: 'Test',
          year: 2022,
          unknownField: 'should be rejected',
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/vehicles', () => {
    it('should return vehicles for the authenticated user', async () => {
      const res = await ctx.http
        .get('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('should return empty array for a user with no vehicles', async () => {
      const res = await ctx.http
        .get('/api/v1/vehicles')
        .set('Authorization', `Bearer ${ctx.mechanicToken}`)
        .expect(200);

      expect(res.body.data).toHaveLength(0);
    });
  });

  describe('GET /api/v1/vehicles/:id', () => {
    it('should return a vehicle by ID', async () => {
      const res = await ctx.http
        .get(`/api/v1/vehicles/${createdVehicleId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.data.id).toBe(createdVehicleId);
    });

    it('should return 404 for non-existent vehicle', async () => {
      await ctx.http
        .get('/api/v1/vehicles/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(404);
    });

    it('should return 404 for another user\'s vehicle', async () => {
      await ctx.http
        .get(`/api/v1/vehicles/${createdVehicleId}`)
        .set('Authorization', `Bearer ${ctx.mechanicToken}`)
        .expect(404);
    });
  });

  describe('PUT /api/v1/vehicles/:id', () => {
    it('should update a vehicle', async () => {
      const res = await ctx.http
        .put(`/api/v1/vehicles/${createdVehicleId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          type: 'Car',
          number: 'MH12AB1234',
          make: 'Honda',
          model: 'Civic',   // changed
          year: 2022,        // changed
          color: 'Blue',     // changed
        })
        .expect(200);

      expect(res.body.data.model).toBe('Civic');
      expect(res.body.data.year).toBe(2022);
      expect(res.body.data.color).toBe('Blue');
    });
  });

  describe('DELETE /api/v1/vehicles/:id', () => {
    it('should delete a vehicle', async () => {
      await ctx.http
        .delete(`/api/v1/vehicles/${createdVehicleId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      // Verify it's gone
      await ctx.http
        .get(`/api/v1/vehicles/${createdVehicleId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(404);
    });
  });
});
