import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  type: process.env.DATABASE_TYPE || 'better-sqlite3',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432', 10),
  username: process.env.DATABASE_USERNAME || 'mechmate',
  password: process.env.DATABASE_PASSWORD || 'mechmate_secret',
  database: process.env.DATABASE_DATABASE || 'data/mechmate.db',
  synchronize: process.env.DATABASE_SYNCHRONIZE !== 'false',
  ssl: process.env.DATABASE_SSL === 'true',
}));
