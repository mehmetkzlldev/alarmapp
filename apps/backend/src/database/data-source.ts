import 'reflect-metadata';
import { config as loadEnv } from 'dotenv';
import { DataSource, DataSourceOptions } from 'typeorm';

// Load .env for CLI-driven migrations (the Nest runtime loads it via ConfigModule).
loadEnv();

const toBool = (v: string | undefined, fallback = false): boolean =>
  v === undefined ? fallback : ['1', 'true', 'yes', 'on'].includes(v.toLowerCase());

/**
 * Shared TypeORM options used both by the Nest runtime (via
 * `DatabaseModule`) and by the TypeORM CLI (`npm run migration:*`).
 *
 * Entities and migrations are resolved by glob so that feature modules owned by
 * other agents (User, RefreshToken, Device, Alarm, MissionType, AlarmMission,
 * MissionHistory, Subscription, NotificationLog, SleepStatistic, Plan) are all
 * registered automatically without an explicit import list here.
 */
export const dataSourceOptions: DataSourceOptions = {
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number.parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USERNAME ?? 'alarmy',
  password: process.env.DB_PASSWORD ?? '',
  database: process.env.DB_NAME ?? 'alarmy',
  ssl: toBool(process.env.DB_SSL)
    ? { rejectUnauthorized: false }
    : false,
  // `.{ts,js}` so the same glob works under ts-node (CLI) and compiled dist.
  entities: [__dirname + '/../**/*.entity.{ts,js}'],
  migrations: [__dirname + '/migrations/*.{ts,js}'],
  // NEVER true in production — migrations are the source of truth.
  synchronize: toBool(process.env.DB_SYNCHRONIZE, false),
  logging: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  migrationsTableName: 'typeorm_migrations',
};

// Default export consumed by the TypeORM CLI (`-d src/database/data-source.ts`).
const dataSource = new DataSource(dataSourceOptions);
export default dataSource;
