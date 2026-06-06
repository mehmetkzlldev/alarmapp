import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AppConfig,
  AwsConfig,
  DatabaseConfig,
  FirebaseConfig,
  GeminiConfig,
  JwtConfig,
  RedisConfig,
  ThrottleConfig,
} from './configuration';

/**
 * Typed, injectable wrapper over Nest's `ConfigService`.
 *
 * Consumers inject `AppConfigService` and read fully-typed config sections
 * instead of stringly-typed `config.get('some.key')` lookups. Every getter is
 * backed by the validated `configuration()` factory, so values are guaranteed
 * present.
 */
@Injectable()
export class AppConfigService {
  constructor(private readonly config: ConfigService<AppConfig, true>) {}

  get env(): string {
    return this.config.get('env', { infer: true });
  }

  get isProduction(): boolean {
    return this.env === 'production';
  }

  get port(): number {
    return this.config.get('port', { infer: true });
  }

  get corsOrigins(): string[] {
    return this.config.get('corsOrigins', { infer: true });
  }

  get freeAlarmLimit(): number {
    return this.config.get('freeAlarmLimit', { infer: true });
  }

  get database(): DatabaseConfig {
    return this.config.get('database', { infer: true });
  }

  get redis(): RedisConfig {
    return this.config.get('redis', { infer: true });
  }

  get jwt(): JwtConfig {
    return this.config.get('jwt', { infer: true });
  }

  get gemini(): GeminiConfig {
    return this.config.get('gemini', { infer: true });
  }

  get firebase(): FirebaseConfig {
    return this.config.get('firebase', { infer: true });
  }

  get aws(): AwsConfig {
    return this.config.get('aws', { infer: true });
  }

  get throttle(): ThrottleConfig {
    return this.config.get('throttle', { infer: true });
  }
}
