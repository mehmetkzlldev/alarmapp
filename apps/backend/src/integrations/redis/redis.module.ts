import { Global, Module } from '@nestjs/common';
import { CacheModule } from '../../common/cache/cache.module';
import { RedisService } from './redis.service';

/**
 * Exposes the raw-string `RedisService` application-wide.
 *
 * Reuses the shared ioredis client (token `REDIS_CLIENT`) that `CacheModule`
 * registers, so no second connection is opened. Marked `@Global` so any feature
 * module can inject `RedisService` without importing this module.
 */
@Global()
@Module({
  imports: [CacheModule],
  providers: [RedisService],
  exports: [RedisService],
})
export class RedisModule {}
