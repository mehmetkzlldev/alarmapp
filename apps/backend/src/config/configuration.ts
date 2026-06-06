/**
 * Central configuration factory.
 *
 * Reads from `process.env` (already validated by `env.validation.ts`) and
 * produces a strongly-typed, namespaced config object that is consumed via the
 * `AppConfigService` typed wrapper. Keeping all env access here means the rest
 * of the codebase never touches `process.env` directly.
 */

export interface DatabaseConfig {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
  ssl: boolean;
  runMigrations: boolean;
  synchronize: boolean;
}

export interface RedisConfig {
  host: string;
  port: number;
  password?: string;
  db: number;
  tls: boolean;
}

export interface JwtConfig {
  accessSecret: string;
  refreshSecret: string;
  accessTtl: string;
  refreshTtl: string;
}

export interface GeminiConfig {
  // Read ONLY on the backend. Never forwarded to clients.
  apiKey: string;
  model: string;
}

export interface FirebaseConfig {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
  credentialsFile?: string;
}

export interface AwsConfig {
  region: string;
  bucket: string;
  accessKeyId: string;
  secretAccessKey: string;
  presignTtl: number;
}

export interface ThrottleConfig {
  ttl: number;
  limit: number;
}

export interface AppConfig {
  env: string;
  port: number;
  corsOrigins: string[];
  freeAlarmLimit: number;
  database: DatabaseConfig;
  redis: RedisConfig;
  jwt: JwtConfig;
  gemini: GeminiConfig;
  firebase: FirebaseConfig;
  aws: AwsConfig;
  throttle: ThrottleConfig;
}

const toBool = (value: string | undefined, fallback = false): boolean => {
  if (value === undefined) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
};

const toInt = (value: string | undefined, fallback: number): number => {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isNaN(parsed) ? fallback : parsed;
};

const safeUrl = (value: string | undefined): URL | null => {
  if (!value) return null;
  try {
    return new URL(value);
  } catch {
    return null;
  }
};

export default (): AppConfig => {
  // Managed hosts (Render, Neon, Upstash, …) hand out a single connection URL.
  // Prefer it when present; otherwise fall back to the individual DB_*/REDIS_*.
  const dbUrl = safeUrl(process.env.DATABASE_URL);
  const redisUrl = safeUrl(process.env.REDIS_URL);

  return {
  env: process.env.NODE_ENV ?? 'development',
  port: toInt(process.env.PORT, 3000),
  corsOrigins: (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  freeAlarmLimit: toInt(process.env.FREE_ALARM_LIMIT, 3),

  database: {
    host: dbUrl?.hostname ?? process.env.DB_HOST ?? 'localhost',
    port: dbUrl ? toInt(dbUrl.port, 5432) : toInt(process.env.DB_PORT, 5432),
    username: dbUrl
      ? decodeURIComponent(dbUrl.username)
      : process.env.DB_USERNAME ?? 'alarmy',
    password: dbUrl
      ? decodeURIComponent(dbUrl.password)
      : process.env.DB_PASSWORD ?? '',
    database: dbUrl
      ? dbUrl.pathname.replace(/^\//, '')
      : process.env.DB_NAME ?? 'alarmy',
    // Managed Postgres requires TLS; default ON when a connection URL is used.
    ssl: dbUrl ? toBool(process.env.DB_SSL, true) : toBool(process.env.DB_SSL),
    runMigrations: toBool(process.env.DB_RUN_MIGRATIONS, true),
    synchronize: toBool(process.env.DB_SYNCHRONIZE, false),
  },

  redis: {
    host: redisUrl?.hostname ?? process.env.REDIS_HOST ?? 'localhost',
    port: redisUrl
      ? toInt(redisUrl.port, 6379)
      : toInt(process.env.REDIS_PORT, 6379),
    password: redisUrl
      ? decodeURIComponent(redisUrl.password) || undefined
      : process.env.REDIS_PASSWORD || undefined,
    db: toInt(process.env.REDIS_DB, 0),
    // rediss:// implies TLS (Upstash uses it).
    tls: redisUrl ? redisUrl.protocol === 'rediss:' : toBool(process.env.REDIS_TLS),
  },

  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? '',
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? '',
    accessTtl: process.env.JWT_ACCESS_TTL ?? '15m',
    refreshTtl: process.env.JWT_REFRESH_TTL ?? '30d',
  },

  gemini: {
    apiKey: process.env.GEMINI_API_KEY ?? '',
    model: process.env.GEMINI_MODEL ?? 'gemini-2.5-flash',
  },

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    // Support `\n`-escaped private keys from single-line env vars.
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    credentialsFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
  },

  aws: {
    region: process.env.AWS_REGION ?? 'us-east-1',
    bucket: process.env.S3_BUCKET ?? '',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID ?? '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY ?? '',
    presignTtl: toInt(process.env.S3_PRESIGN_TTL, 300),
  },

  throttle: {
    ttl: toInt(process.env.THROTTLE_TTL, 60),
    limit: toInt(process.env.THROTTLE_LIMIT, 120),
  },
  };
};
