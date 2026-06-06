import { Inject, Injectable, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../common/cache/cache.service';

/**
 * Raw-string Redis wrapper.
 *
 * Unlike `CacheService` (which JSON-encodes/decodes for you), `RedisService`
 * deals in raw strings: callers serialize themselves. This suits consumers that
 * need full control over the stored representation (e.g. the subscriptions
 * service revives `Date` fields after parsing).
 *
 * It shares the single ioredis connection provided by `CacheModule` via the
 * `REDIS_CLIENT` token, so there is exactly one Redis client process-wide.
 */
@Injectable()
export class RedisService {
  private readonly logger = new Logger(RedisService.name);

  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  /** Get a raw string value, or null on miss/error. */
  async get(key: string): Promise<string | null> {
    try {
      return await this.redis.get(key);
    } catch (err) {
      this.logger.warn(`get failed for ${key}: ${(err as Error).message}`);
      return null;
    }
  }

  /** Set a raw string value with an optional TTL (seconds). */
  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    try {
      if (ttlSeconds && ttlSeconds > 0) {
        await this.redis.set(key, value, 'EX', ttlSeconds);
      } else {
        await this.redis.set(key, value);
      }
    } catch (err) {
      this.logger.warn(`set failed for ${key}: ${(err as Error).message}`);
    }
  }

  /** Delete one or more keys. */
  async del(...keys: string[]): Promise<void> {
    if (keys.length === 0) return;
    try {
      await this.redis.del(...keys);
    } catch (err) {
      this.logger.warn(
        `del failed for [${keys.join(',')}]: ${(err as Error).message}`,
      );
    }
  }

  /** Existence check. */
  async exists(key: string): Promise<boolean> {
    try {
      return (await this.redis.exists(key)) === 1;
    } catch {
      return false;
    }
  }
}
