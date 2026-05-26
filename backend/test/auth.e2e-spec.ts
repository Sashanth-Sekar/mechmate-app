import { TestAppContext, createTestApp, createDevIdToken } from './helpers/test-app';

describe('Auth (e2e)', () => {
  let ctx: TestAppContext;

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  // ------------------------------------------------------------------
  // POST /api/v1/auth/firebase
  // ------------------------------------------------------------------
  describe('POST /api/v1/auth/firebase', () => {
    it('should authenticate with a valid dev-mode Firebase ID token', async () => {
      const idToken = createDevIdToken('new-user-uid', 'new@test.com', 'New User');
      const res = await ctx.http
        .post('/api/v1/auth/firebase')
        .send({ idToken, role: 'owner', displayName: 'New User' })
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.user).toBeDefined();
      expect(res.body.data.user.email).toBe('new@test.com');
      expect(res.body.data.user.firebaseUid).toBe('new-user-uid');
      expect(res.body.data.token).toBeDefined();
    });

    it('should return existing user on duplicate firebaseUid', async () => {
      const idToken = createDevIdToken('test-owner-uid', 'owner@test.com', 'Test Owner');
      const res = await ctx.http
        .post('/api/v1/auth/firebase')
        .send({ idToken, role: 'owner' })
        .expect(200);

      expect(res.body.data.user.id).toBe(ctx.ownerUser.id);
    });

    it('should reject an empty idToken (DTO validation fails first)', async () => {
      const res = await ctx.http
        .post('/api/v1/auth/firebase')
        .send({ idToken: '', role: 'owner' })
        .expect(400);

      expect(res.body.success).toBe(false);
    });

    it('should reject an invalid JWT token', async () => {
      const res = await ctx.http
        .post('/api/v1/auth/firebase')
        .send({ idToken: 'not-a-jwt', role: 'owner' })
        .expect(401);

      expect(res.body.success).toBe(false);
    });
  });

  // ------------------------------------------------------------------
  // POST /api/v1/auth/register
  // ------------------------------------------------------------------
  describe('POST /api/v1/auth/register', () => {
    it('should register a new user in dev mode', async () => {
      const idToken = createDevIdToken('register-uid', 'register@test.com', 'Register User');
      const res = await ctx.http
        .post('/api/v1/auth/register')
        .send({ idToken, role: 'mechanic', email: 'register@test.com', displayName: 'Register User' })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.user.email).toBe('register@test.com');
    });
  });

  // ------------------------------------------------------------------
  // GET /api/v1/auth/profile
  // ------------------------------------------------------------------
  describe('GET /api/v1/auth/profile', () => {
    it('should reject unauthenticated requests', async () => {
      await ctx.http.get('/api/v1/auth/profile').expect(401);
    });

    it('should return the authenticated user profile', async () => {
      const res = await ctx.http
        .get('/api/v1/auth/profile')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(ctx.ownerUser.id);
      expect(res.body.data.email).toBe(ctx.ownerUser.email);
    });
  });

  // ------------------------------------------------------------------
  // PATCH /api/v1/auth/profile
  // ------------------------------------------------------------------
  describe('PATCH /api/v1/auth/profile', () => {
    it('should update profile fields', async () => {
      const res = await ctx.http
        .patch('/api/v1/auth/profile')
        .set('Authorization', `Bearer ${ctx.ownerToken}`)
        .send({ name: 'Updated Name', phone: '+9999999999' })
        .expect(200);

      expect(res.body.data.name).toBe('Updated Name');
      expect(res.body.data.phone).toBe('+9999999999');
    });
  });
});
