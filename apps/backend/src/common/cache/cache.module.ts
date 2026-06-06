import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { CacheService, REDIS_CLIENT } from './cache.service';

/**
 * Global cache module. Provides a single shared ioredis client + CacheService
 * to the whole application so every feature module can inject CacheService
 * without re-importing it.
 *
 * REDIS_URL is read from config (12-factor); no secret is hardcoded.
 */
@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Redis => {
        // Prefer a full REDIS_URL if provided; otherwise assemble from the
        // discrete host/port/password/db/tls fields used by the shared env.
        const url = config.get<string>('REDIS_URL');
        const common = {
          // Fail fast rather than buffering commands forever if Redis is down.
          maxRetriesPerRequest: 2,
          enableReadyCheck: true,
          lazyConnect: false,
        };
        if (url) {
          return new Redis(url, common);
        }
        // Joi may coerce REDIS_TLS to a real boolean, so accept either form.
        const tlsRaw = config.get('REDIS_TLS');
        const tls = tlsRaw === true || tlsRaw === 'true';
        return new Redis({
          host: config.get<string>('REDIS_HOST') ?? 'localhost',
          port: Number(config.get<string>('REDIS_PORT') ?? 6379),
          password: config.get<string>('REDIS_PASSWORD') || undefined,
          db: Number(config.get<string>('REDIS_DB') ?? 0),
          ...(tls ? { tls: {} } : {}),
          ...common,
        });
      },
    },
    CacheService,
  ],
  exports: [CacheService, REDIS_CLIENT],
})
export class CacheModule {}
