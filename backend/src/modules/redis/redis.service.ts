import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

/**
 * Lightweight cache wrapper around ioredis.
 *
 * All methods gracefully degrade when Redis is unavailable (e.g. in test
 * environments or when Redis hasn't been started). This makes the cache
 * optional — the application still works without it.
 */
@Injectable()
export class RedisService {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;
  private _available = false;

  constructor(private readonly configService: ConfigService) {
    this._init();
  }

  private _init(): void {
    const host = this.configService.get<string>('app.redis.host', 'localhost');
    const port = this.configService.get<number>('app.redis.port', 6379);

    // Don't attempt connection when Redis is not configured
    if (!host || host === '') {
      this.logger.warn('Redis host not configured — caching is disabled');
      return;
    }

    try {
      this.client = new Redis({
        host,
        port,
        maxRetriesPerRequest: 3,
        retryStrategy(times: number) {
          if (times > 3) return null; // Stop retrying after 3 attempts
          return Math.min(times * 200, 2000);
        },
        lazyConnect: true, // Don't fail on startup if Redis is down
      });

      this.client.on('ready', () => {
        this._available = true;
        this.logger.log('Redis connected');
      });

      this.client.on('error', (err: Error) => {
        this._available = false;
        this.logger.warn(`Redis error: ${err.message}`);
      });

      this.client.on('end', () => {
        this._available = false;
      });

      // Attempt connection (non-blocking)
      this.client.connect().catch((err: Error) => {
        this._available = false;
        this.logger.warn(`Redis unavailable — caching is disabled: ${err.message}`);
      });
    } catch (err) {
      this._available = false;
      this.logger.warn(`Failed to create Redis client — caching is disabled`);
    }
  }

  /** Whether the Redis client is connected and ready. */
  get isAvailable(): boolean {
    return this._available;
  }

  /**
   * Get a cached value. Returns `null` when the key is missing or Redis is
   * unavailable.
   */
  async get<T = string>(key: string): Promise<T | null> {
    if (!this._available || !this.client) return null;
    try {
      const raw = await this.client.get(key);
      if (raw == null) return null;
      return JSON.parse(raw) as T;
    } catch (err) {
      this.logger.debug(`Cache GET error for "${key}": ${err}`);
      return null;
    }
  }

  /**
   * Set a cached value with an optional TTL (in seconds, default 60).
   */
  async set(key: string, value: unknown, ttlSeconds = 60): Promise<void> {
    if (!this._available || !this.client) return;
    try {
      const raw = JSON.stringify(value);
      await this.client.set(key, raw, 'EX', ttlSeconds);
    } catch (err) {
      this.logger.debug(`Cache SET error for "${key}": ${err}`);
    }
  }

  /**
   * Delete one or more keys.
   */
  async del(...keys: string[]): Promise<void> {
    if (!this._available || !this.client) return;
    try {
      await this.client.del(keys);
    } catch (err) {
      this.logger.debug(`Cache DEL error: ${err}`);
    }
  }

  /**
   * Delete all keys matching a pattern (e.g. `workshops:*`).
   */
  async delPattern(pattern: string): Promise<void> {
    if (!this._available || !this.client) return;
    try {
      let cursor = '0';
      do {
        const result = await this.client.scan(
          cursor,
          'MATCH',
          pattern,
          'COUNT',
          50,
        );
        cursor = result[0];
        const keys = result[1] as string[];
        if (keys.length > 0) {
          await this.client.del(keys);
        }
      } while (cursor !== '0');
    } catch (err) {
      this.logger.debug(`Cache DEL pattern error for "${pattern}": ${err}`);
    }
  }

  /**
   * Wraps an async factory function with cache-aside pattern.
   *
   * If the value exists in cache it is returned immediately; otherwise the
   * factory is called, its result is cached, and then returned.
   */
  async getOrSet<T>(
    key: string,
    factory: () => Promise<T>,
    ttlSeconds = 60,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached != null) return cached;

    const value = await factory();
    await this.set(key, value, ttlSeconds);
    return value;
  }

  /**
   * Clean shutdown — disconnect the Redis client.
   */
  async onApplicationShutdown(): Promise<void> {
    if (this.client) {
      await this.client.quit().catch(() => {});
      this.client = null;
      this._available = false;
    }
  }
}
