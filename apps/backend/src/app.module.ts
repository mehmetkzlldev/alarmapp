import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule, seconds } from '@nestjs/throttler';

import { AppConfigModule, AppConfigService } from './config';
import { DatabaseModule } from './database/database.module';
import { CacheModule } from './common/cache/cache.module';
import { RedisModule } from './integrations/redis/redis.module';
import { HealthModule } from './health/health.module';

import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { TransformResponseInterceptor } from './common/interceptors/transform-response.interceptor';

// Feature modules (each owns its controllers/services/entities; wired here per
// the API contract). Authentication is enforced per-route via `@UseGuards`
// inside each controller, so JwtAuthGuard is intentionally NOT a global guard
// (the public /auth/* and /health routes simply omit it).
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { DevicesModule } from './modules/devices/devices.module';
import { AlarmsModule } from './modules/alarms/alarms.module';
import { MissionsModule } from './modules/missions/missions.module';
import { ObjectDetectionModule } from './modules/object-detection/object-detection.module';
import { AiMissionModule } from './modules/ai-mission/ai-mission.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { SleepModule } from './modules/sleep/sleep.module';

/**
 * Root application module.
 *
 * Composes global infrastructure (config, DB, Redis cache, BullMQ, throttling,
 * scheduling), registers the global filter/interceptor pipeline plus the global
 * rate-limit guard, and mounts every feature module behind the `/api/v1` prefix
 * (configured in `main.ts`).
 */
@Module({
  imports: [
    // --- Infrastructure ---
    AppConfigModule,
    DatabaseModule,
    CacheModule, // global ioredis client + CacheService (shared)
    RedisModule, // global raw-string RedisService (shares the same client)
    ScheduleModule.forRoot(),

    // BullMQ shares the same Redis instance for alarm/notification queues.
    BullModule.forRootAsync({
      imports: [AppConfigModule],
      inject: [AppConfigService],
      useFactory: (config: AppConfigService) => {
        const { host, port, password, db } = config.redis;
        return {
          connection: {
            host,
            port,
            password: password || undefined,
            db,
          },
          defaultJobOptions: {
            attempts: 3,
            backoff: { type: 'exponential', delay: 2000 },
            removeOnComplete: 1000,
            removeOnFail: 5000,
          },
        };
      },
    }),

    // Global rate limiting backed by config (THROTTLE_TTL / THROTTLE_LIMIT).
    // Individual routes tighten this with `@Throttle()` (e.g. /auth/login).
    ThrottlerModule.forRootAsync({
      imports: [AppConfigModule],
      inject: [AppConfigService],
      useFactory: (config: AppConfigService) => ({
        throttlers: [
          {
            ttl: seconds(config.throttle.ttl),
            limit: config.throttle.limit,
          },
        ],
      }),
    }),

    // --- Feature modules ---
    AuthModule,
    UsersModule,
    DevicesModule,
    AlarmsModule,
    MissionsModule,
    ObjectDetectionModule,
    AiMissionModule,
    NotificationsModule,
    SubscriptionsModule,
    SleepModule,
    HealthModule,
  ],
  providers: [
    // Global rate-limit guard (applies the configured throttler to every route).
    { provide: APP_GUARD, useClass: ThrottlerGuard },

    // Global error envelope: { statusCode, message, error, path, timestamp }.
    { provide: APP_FILTER, useClass: AllExceptionsFilter },

    // Global interceptors (logging outermost, then response normalization).
    { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
    { provide: APP_INTERCEPTOR, useClass: TransformResponseInterceptor },
  ],
})
export class AppModule {}
