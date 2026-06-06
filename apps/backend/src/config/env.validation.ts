import * as Joi from 'joi';

/**
 * Joi schema used by `ConfigModule.forRoot({ validationSchema })`.
 *
 * The process fails fast at boot if a required variable is missing or
 * malformed, surfacing misconfiguration before any request is served.
 */
export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  PORT: Joi.number().port().default(3000),
  CORS_ORIGINS: Joi.string().allow('').default(''),
  FREE_ALARM_LIMIT: Joi.number().integer().min(0).default(3),

  // Postgres — provide DATABASE_URL (managed hosts) OR the discrete DB_* vars.
  DATABASE_URL: Joi.string().optional(),
  DB_HOST: Joi.string().when('DATABASE_URL', {
    is: Joi.exist(),
    then: Joi.optional(),
    otherwise: Joi.required(),
  }),
  DB_PORT: Joi.number().port().default(5432),
  DB_USERNAME: Joi.string().when('DATABASE_URL', {
    is: Joi.exist(),
    then: Joi.optional(),
    otherwise: Joi.required(),
  }),
  DB_PASSWORD: Joi.string().allow('').when('DATABASE_URL', {
    is: Joi.exist(),
    then: Joi.optional(),
    otherwise: Joi.required(),
  }),
  DB_NAME: Joi.string().when('DATABASE_URL', {
    is: Joi.exist(),
    then: Joi.optional(),
    otherwise: Joi.required(),
  }),
  DB_SSL: Joi.boolean().truthy('true').falsy('false').default(false),
  DB_RUN_MIGRATIONS: Joi.boolean().truthy('true').falsy('false').default(true),
  DB_SYNCHRONIZE: Joi.boolean().truthy('true').falsy('false').default(false),

  // Redis — provide REDIS_URL (managed hosts) OR the discrete REDIS_* vars.
  REDIS_URL: Joi.string().optional(),
  REDIS_HOST: Joi.string().when('REDIS_URL', {
    is: Joi.exist(),
    then: Joi.optional(),
    otherwise: Joi.required(),
  }),
  REDIS_PORT: Joi.number().port().default(6379),
  REDIS_PASSWORD: Joi.string().allow('').optional(),
  REDIS_DB: Joi.number().integer().min(0).default(0),
  REDIS_TLS: Joi.boolean().truthy('true').falsy('false').default(false),

  // JWT — enforce a minimum secret length to avoid weak signing keys.
  JWT_ACCESS_SECRET: Joi.string().min(16).required(),
  JWT_REFRESH_SECRET: Joi.string().min(16).required(),
  JWT_ACCESS_TTL: Joi.string().default('15m'),
  JWT_REFRESH_TTL: Joi.string().default('30d'),

  // Gemini (backend only)
  GEMINI_API_KEY: Joi.string().required(),
  GEMINI_MODEL: Joi.string().default('gemini-2.5-flash'),

  // Firebase — either a credentials file OR the discrete trio.
  GOOGLE_APPLICATION_CREDENTIALS: Joi.string().optional(),
  FIREBASE_PROJECT_ID: Joi.string().optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().optional(),

  // AWS S3 — optional; object detection now sends images inline (no S3 needed).
  AWS_REGION: Joi.string().default('us-east-1'),
  S3_BUCKET: Joi.string().allow('').default(''),
  AWS_ACCESS_KEY_ID: Joi.string().allow('').default(''),
  AWS_SECRET_ACCESS_KEY: Joi.string().allow('').default(''),
  S3_PRESIGN_TTL: Joi.number().integer().min(30).max(3600).default(300),

  // Throttling
  THROTTLE_TTL: Joi.number().integer().min(1).default(60),
  THROTTLE_LIMIT: Joi.number().integer().min(1).default(120),
});
