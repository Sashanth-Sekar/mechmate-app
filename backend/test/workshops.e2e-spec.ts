import { TestAppContext, createTestApp } from './helpers/test-app';

describe('Workshops (e2e)', () => {
  let ctx: TestAppContext;
  let createdWorkshopId: string;

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
    it('should reject unauthenticated POST', async () => {
      await ctx.http.post('/api/v1/workshops').send({}).expect(401);
    });

    it('should reject unauthenticated PATCH', async () => {
      await ctx.http.patch('/api/v1/workshops/some-id').send({}).expect(401);
    });

    it('should reject unauthenticated GET /my-workshops', async () => {
      await ctx.http.get('/api/v1/workshops/my-workshops').expect(401);
    });
  });

  // ------------------------------------------------------------------
  // Public listing
  // ------------------------------------------------------------------
  describe('Public listing', () => {
    it('GET /api/v1/workshops should return empty list initially', async () => {
      const res = await ctx.http.get('/api/v1/workshops').expect(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.data).toEqual([]);
      expect(res.body.data.total).toBe(0);
    });

    it('should support pagination params', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops?page=1&limit=10')
        .expect(200);
      expect(res.body.data.page).toBe(1);
      expect(res.body.data.limit).toBe(10);
    });
  });

  // ------------------------------------------------------------------
  // POST /api/v1/workshops – create
  // ------------------------------------------------------------------
  describe('POST /api/v1/workshops', () => {
    it('should create a new workshop', async () => {
      const res = await ctx.http
        .post('/api/v1/workshops')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          name: 'Test Auto Garage',
          address: '123 Main Street',
          city: 'Mumbai',
          pincode: '400001',
          phone: '+9123456789',
          email: 'garage@test.com',
          description: 'A test workshop for e2e tests',
          services: ['Oil Change', 'Engine Repair'],
          vehicleTypes: ['Car', 'Bike'],
          openTime: '08:00',
          closeTime: '20:00',
        })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe('Test Auto Garage');
      expect(res.body.data.city).toBe('Mumbai');
      expect(res.body.data.ownerId).toBe(ctx.ownerUser.id);
      expect(res.body.data.id).toBeDefined();

      createdWorkshopId = res.body.data.id;
    });

    it('should reject missing required fields', async () => {
      const res = await ctx.http
        .post('/api/v1/workshops')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ name: 'Incomplete' })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject empty name', async () => {
      const res = await ctx.http
        .post('/api/v1/workshops')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          name: '',
          address: '123 Street',
          city: 'City',
          pincode: '123456',
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject extra fields (forbidNonWhitelisted)', async () => {
      const res = await ctx.http
        .post('/api/v1/workshops')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          name: 'Extra Fields Workshop',
          address: '456 Lane',
          city: 'Delhi',
          pincode: '110001',
          unknownField: 'should be rejected',
        })
        .expect(400);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/workshops – list (after creation)
  // ------------------------------------------------------------------
  describe('GET /api/v1/workshops (after creation)', () => {
    it('should return the created workshop in the list', async () => {
      const res = await ctx.http.get('/api/v1/workshops').expect(200);
      expect(res.body.data.data.length).toBeGreaterThanOrEqual(1);
      const workshop = res.body.data.data.find(
        (w: any) => w.id === createdWorkshopId,
      );
      expect(workshop).toBeDefined();
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/workshops/search
  // ------------------------------------------------------------------
  describe('GET /api/v1/workshops/search', () => {
    it('should find workshop by name', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops/search?q=Test%20Auto')
        .expect(200);

      // Response is wrapped by the interceptor: { success, data }
      // and the service returns a plain array
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].name).toContain('Test Auto');
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/workshops/city/:city
  // ------------------------------------------------------------------
  describe('GET /api/v1/workshops/city/:city', () => {
    it('should return workshops for a specific city', async () => {
      // The workshop must be verified to appear in city results
      await ctx.workshopRepo.update(createdWorkshopId, { isVerified: true });

      const res = await ctx.http
        .get('/api/v1/workshops/city/Mumbai')
        .expect(200);

      // Response is wrapped by the interceptor: { success, data }
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      const mumbaiWorkshops = res.body.data.filter(
        (w: any) => w.city === 'Mumbai',
      );
      expect(mumbaiWorkshops.length).toBeGreaterThanOrEqual(1);
    });

    it('should return empty for a city with no workshops', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops/city/UnknownCity')
        .expect(200);

      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data).toHaveLength(0);
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/workshops/:id
  // ------------------------------------------------------------------
  describe('GET /api/v1/workshops/:id', () => {
    it('should return workshop details by ID', async () => {
      const res = await ctx.http
        .get(`/api/v1/workshops/${createdWorkshopId}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(createdWorkshopId);
      expect(res.body.data.name).toBe('Test Auto Garage');
      expect(res.body.data.owner).toBeDefined();
    });

    it('should return 404 for non-existent workshop', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops/00000000-0000-0000-0000-000000000000')
        .expect(404);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/workshops/my-workshops
  // ------------------------------------------------------------------
  describe('GET /api/v1/workshops/my-workshops', () => {
    it('should return workshops owned by the authenticated user', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops/my-workshops')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      // Response is wrapped by the interceptor: { success, data }
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data[0].ownerId).toBe(ctx.ownerUser.id);
    });

    it('should return empty for mechanic user', async () => {
      const res = await ctx.http
        .get('/api/v1/workshops/my-workshops')
        .set('Authorization', `Bearer ${ctx.mechanicToken}`)
        .expect(200);

      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data).toHaveLength(0);
    });
  });

  // ------------------------------------------------------------------
  // PATCH /api/v1/workshops/:id
  // ------------------------------------------------------------------
  describe('PATCH /api/v1/workshops/:id', () => {
    it('should update workshop fields', async () => {
      const res = await ctx.http
        .patch(`/api/v1/workshops/${createdWorkshopId}`)
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({
          name: 'Updated Garage Name',
          description: 'Updated description for the workshop',
          openTime: '07:00',
        })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe('Updated Garage Name');
      expect(res.body.data.description).toBe(
        'Updated description for the workshop',
      );
      expect(res.body.data.openTime).toBe('07:00');
    });

    it('should reject update by non-owner (mechanic user)', async () => {
      const res = await ctx.http
        .patch(`/api/v1/workshops/${createdWorkshopId}`)
        .set('Authorization', `Bearer ${ctx.mechanicToken}`)
        .send({ name: 'Hacked Name' })
        .expect(403);

      expect(res.body.success).toBe(false);
    });
  });
});
