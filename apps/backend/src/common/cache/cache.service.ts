import {
  Inject,
  Injectable,
  Logger,
  OnModuleDestroy,
} from '@nestjs/common';
import Redis from 'ioredis';

export const REDIS_CLIENT = 'REDIS_CLIENT';

/**
 * Thin, typed wrapper around the shared ioredis client.
 *
 * Used here to cache user profiles (`user:profile:<id>`) and the math-mission
 * answers (owned by the missions module). Keys are namespaced by convention so
 * different domains never collide.
 *
 * All methods are defensive: a Redis outage must never take down a request that
 * can be served from Postgres, so read/write failures are logged and swallowed.
 */
@Injectable()
export class CacheService implements OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);

  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  /** Fetch and JSON-parse a cached value, or null on miss / error. */
  async get<T>(key: string): Promise<T | null> {
    try {
      const raw = await this.redis.get(key);
      return raw ? (JSON.parse(raw) as T) : null;
    } catch (err) {
      this.logger.warn(`cache get failed for ${key}: ${(err as Error).message}`);
      return null;
    }
  }

  /** JSON-serialize and store a value with an optional TTL (seconds). */
  async set<T>(key: string, value: T, ttlSeconds?: number): Promise<void> {
    try {
      const payload = JSON.stringify(value);
      if (ttlSeconds && ttlSeconds > 0) {
        await this.redis.set(key, payload, 'EX', ttlSeconds);
      } else {
        await this.redis.set(key, payload);
      }
    } catch (err) {
      this.logger.warn(`cache set failed for ${key}: ${(err as Error).message}`);
    }
  }

  /** Delete one or more keys. Safe to call with keys that do not exist. */
  async del(...keys: string[]): Promise<void> {
    if (keys.length === 0) return;
    try {
      await this.redis.del(...keys);
    } catch (err) {
      this.logger.warn(
        `cache del failed for [${keys.join(',')}]: ${(err as Error).message}`,
      );
    }
  }

  /**
   * Alias for `set(key, value, ttlSeconds)` with an explicit, required TTL.
   * Reads more clearly at call sites that always want expiry.
   */
  async withTtl<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
    await this.set(key, value, ttlSeconds);
  }

  // --------------------------------------------------------------------------
  // Math-mission answer cache helpers
  //
  // The math mission generates a problem server-side and returns only a random
  // `problemId` + the rendered expression. The correct numeric answer is cached
  // here keyed by problemId and is NEVER sent to the client; the verify endpoint
  // compares the submitted answer against this cached value.
  // --------------------------------------------------------------------------

  /** TTL (seconds) a generated math problem stays solvable before expiring. */
  private static readonly MATH_ANSWER_TTL = 600;
  private static readonly MATH_KEY_PREFIX = 'mission:math:';

  private mathKey(problemId: string): string {
    return `${CacheService.MATH_KEY_PREFIX}${problemId}`;
  }

  /** Cache the correct answer for a generated math problem (server-side only). */
  async cacheMathAnswer(problemId: string, answer: number): Promise<void> {
    await this.withTtl(
      this.mathKey(problemId),
      answer,
      CacheService.MATH_ANSWER_TTL,
    );
  }

  /** Retrieve a cached math answer, or null if unknown/expired. */
  async getMathAnswer(problemId: string): Promise<number | null> {
    return this.get<number>(this.mathKey(problemId));
  }

  /** Invalidate a math problem after a successful (single-use) verification. */
  async clearMathAnswer(problemId: string): Promise<void> {
    await this.del(this.mathKey(problemId));
  }

  async onModuleDestroy(): Promise<void> {
    // The client is provided by RedisModule; quitting here is idempotent and
    // guards against leaked connections during graceful shutdown.
    try {
      await this.redis.quit();
    } catch {
      /* already closed */
    }
  }
}
