import { TestAppContext, createTestApp } from './helpers/test-app';

describe('App (e2e)', () => {
  let ctx: TestAppContext;

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  it('GET /api/v1 should return 404 (no root route)', async () => {
    // The app uses the global prefix /api/v1 and has no root handler
    await ctx.http.get('/').expect(404);
  });

  it('GET /api/v1/vehicles should return 401 (auth required)', async () => {
    await ctx.http.get('/api/v1/vehicles').expect(401);
  });
});
