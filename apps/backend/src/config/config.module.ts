import { Global, Module } from '@nestjs/common';
import { ConfigModule as NestConfigModule } from '@nestjs/config';
import configuration from './configuration';
import { envValidationSchema } from './env.validation';
import { AppConfigService } from './app-config.service';

/**
 * Global config module.
 *
 * Loads `.env`, validates it with Joi, registers the typed `configuration()`
 * factory, and exposes the `AppConfigService` everywhere. Marked `@Global` so
 * feature modules don't need to re-import it.
 */
@Global()
@Module({
  imports: [
    NestConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      expandVariables: true,
      load: [configuration],
      validationSchema: envValidationSchema,
      validationOptions: {
        // Surface every problem at once and forbid unknown vars in prod.
        abortEarly: false,
      },
    }),
  ],
  providers: [AppConfigService],
  exports: [AppConfigService],
})
export class AppConfigModule {}
