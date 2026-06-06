import { Module } from '@nestjs/common';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';
import { AppConfigModule, AppConfigService } from '../config';
import { dataSourceOptions } from './data-source';

/**
 * Wires TypeORM into Nest using async factory configuration so connection
 * details come from the validated `AppConfigService` rather than raw env.
 *
 * The base `dataSourceOptions` (entity/migration globs, table name) are reused
 * to keep the runtime and CLI in lockstep; only the connection-specific and
 * lifecycle flags are overlaid from config.
 */
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [AppConfigModule],
      inject: [AppConfigService],
      useFactory: (config: AppConfigService): TypeOrmModuleOptions => {
        const db = config.database;
        return {
          ...dataSourceOptions,
          host: db.host,
          port: db.port,
          username: db.username,
          password: db.password,
          database: db.database,
          ssl: db.ssl ? { rejectUnauthorized: false } : false,
          synchronize: db.synchronize,
          // Auto-run pending migrations on boot when enabled.
          migrationsRun: db.runMigrations,
          autoLoadEntities: true,
        } as TypeOrmModuleOptions;
      },
    }),
  ],
})
export class DatabaseModule {}
