# Alarmy Backend

NestJS 10 backend for the AI alarm clock app. TypeScript, TypeORM (Postgres),
Redis (cache + BullMQ), Gemini, Firebase (FCM), and S3 for object-detection
uploads.

## Base path

All routes are served under `/api/v1` (global prefix + URI versioning).
Authentication: `Authorization: Bearer <accessToken>`.

## Getting started

```bash
cp .env.example .env        # fill in real values (never commit .env)
npm install
npm run start:dev           # watch mode on :PORT (default 3000)
```

Swagger UI (non-production only): `http://localhost:3000/docs`.
Health check: `GET /api/v1/health` -> `{ "status": "ok" }`.

## Scripts

| Script | Purpose |
| --- | --- |
| `npm run start:dev` | Watch-mode dev server |
| `npm run build` | Compile to `dist/` |
| `npm run start:prod` | Run compiled server |
| `npm test` / `npm run test:e2e` | Unit / e2e tests |
| `npm run migration:generate -- src/database/migrations/Name` | Generate a migration |
| `npm run migration:run` | Apply pending migrations |
| `npm run migration:revert` | Revert the last migration |

## Architecture

- `src/config` — typed, Joi-validated configuration (`AppConfigService`).
- `src/database` — TypeORM `DataSource` (CLI + runtime) and `DatabaseModule`.
- `src/common/cache` — shared ioredis client + `CacheService` (JSON helpers,
  math-mission answer cache).
- `src/integrations` — Gemini, Firebase, S3, and a raw-string `RedisService`.
- `src/common` — guards (`JwtAuthGuard`, `RolesGuard`, `PremiumGuard`),
  decorators (`@Public`, `@Roles`, `@Premium`, `@CurrentUser`), interceptors
  (logging, response-transform, timeout), the global exception filter, pipes,
  and shared DTOs.
- `src/modules/*` — feature modules (auth, users, devices, alarms, missions,
  object-detection, ai-mission, notifications, subscriptions, sleep).

## Security

- Secrets come only from env (`process.env`); none are hardcoded. The Gemini key
  is read server-side only and never reaches the Flutter client.
- Passwords hashed with argon2; refresh tokens stored hashed (SHA-256) with
  rotation + reuse detection.
- helmet, CORS allowlist, global `ValidationPipe` (whitelist + transform), and
  `ThrottlerGuard` rate limiting are enabled globally.
- S3 access is via short-TTL presigned URLs against a private bucket.
- Store receipts are validated server-side; the client is never trusted for
  premium entitlement.
