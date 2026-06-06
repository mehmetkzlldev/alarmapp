# Alarmy-style AI Alarm Clock

An AI-powered alarm clock app (Alarmy-style) that makes waking up unavoidable: alarms that
only dismiss after the user completes a *mission* (math, photo of a barcode/QR, typing,
shake, etc.), reinforced by AI-generated wake-up content and analytics. The system is a
mobile app (Flutter) backed by a NestJS API, PostgreSQL, Redis, and S3, with Google Gemini
powering the AI features **on the server side only**.

---

## Table of contents

1. [Architecture summary](#architecture-summary)
2. [The 7 deliverables](#the-7-deliverables)
3. [Monorepo layout](#monorepo-layout)
4. [Quickstart — backend](#quickstart--backend)
5. [Quickstart — Flutter mobile](#quickstart--flutter-mobile)
6. [Security](#security)
7. [Further docs](#further-docs)

---

## Architecture summary

```
                        ┌───────────────────────────────────────────┐
                        │                Mobile (Flutter)            │
                        │  - Local alarm scheduling (exact alarms)   │
                        │  - Missions (math / photo / shake / type)  │
                        │  - FCM push for sync + critical alerts     │
                        │  - Talks ONLY to the backend API (JWT)     │
                        └───────────────────┬───────────────────────┘
                                            │ HTTPS (REST, Bearer JWT)
                                            ▼
        ┌──────────────────────────────────────────────────────────────────┐
        │                         Backend API (NestJS)                       │
        │                                                                    │
        │  Auth (argon2 + JWT access/refresh)   Alarms CRUD   Missions       │
        │  AI proxy → Gemini (server key only)  IAP receipt validation       │
        │  Push (FCM)   Analytics   S3 presigned URLs (private bucket)       │
        │                                                                    │
        │  helmet · CORS allowlist · ThrottlerGuard · class-validator DTOs   │
        └───────┬───────────────┬────────────────┬───────────────┬──────────┘
                │               │                │               │
                ▼               ▼                ▼               ▼
        ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌────────────┐
        │ PostgreSQL │   │   Redis    │   │     S3     │   │   Gemini   │
        │ (TypeORM)  │   │ cache/queue│   │ (private)  │   │ (AI, key   │
        │            │   │            │   │ presigned  │   │  in env)   │
        └────────────┘   └────────────┘   └────────────┘   └────────────┘
```

- **Mobile (Flutter)** owns the real-time alarm experience: it schedules exact, wake-locked
  alarms locally so they fire even offline, and runs the dismissal missions. It never holds
  third-party API keys — all AI and premium logic lives behind the backend.
- **Backend (NestJS + TypeORM)** is the single trusted boundary. It authenticates users,
  persists alarms/missions/analytics, proxies Gemini requests, validates in-app-purchase
  receipts server-side, issues short-TTL S3 presigned URLs, and sends push via FCM.
- **PostgreSQL** is the system of record (schema in [`database/schema.sql`](database/schema.sql)).
- **Redis** backs caching, rate limiting, and background job queues (e.g. push fan-out).
- **S3** stores user media (mission photos, generated audio) in a private bucket; clients
  read/write only through short-lived presigned URLs.
- **Gemini** generates wake-up content and powers AI missions. The API key is read **only**
  from the backend environment (`process.env.GEMINI_API_KEY`) and is never shipped to the app.

---

## The 7 deliverables

| # | Deliverable | Location | Description |
|---|-------------|----------|-------------|
| 1 | **Database schema** | `database/schema.sql` | Postgres DDL: users, alarms, missions, dismissals, subscriptions, refresh tokens, analytics. |
| 2 | **Backend API** | `apps/backend` | NestJS + TypeORM service: auth, alarms, missions, AI proxy, IAP, push, S3, analytics. |
| 3 | **Flutter mobile app** | `apps/mobile` | Cross-platform client: alarm scheduling, missions, FCM, IAP, API client. |
| 4 | **Infrastructure / deploy** | `infra` | AWS deployment notes & IaC pointers (ECS, RDS, ElastiCache, S3, CloudFront/WAF). |
| 5 | **Container orchestration** | `docker-compose.yml` | Local Postgres + Redis + backend wiring for one-command dev. |
| 6 | **Project documentation** | `README.md`, `SETUP.md`, `infra/README.md` | Overview, onboarding checklist, deployment notes. |
| 7 | **Environment & config templates** | `apps/backend/.env.example`, `.gitignore` | Safe placeholders + ignore rules so secrets never land in git. |

---

## Monorepo layout

```
alarmapps/
├── apps/
│   ├── backend/            # NestJS API (TypeORM, Gemini proxy, IAP, push, S3)
│   │   ├── src/
│   │   ├── .env.example    # placeholders only — copy to .env
│   │   └── package.json
│   └── mobile/             # Flutter app (Dart)
│       ├── lib/
│       ├── android/
│       ├── ios/
│       └── pubspec.yaml
├── database/
│   └── schema.sql          # Postgres DDL (mounted by docker-compose on first boot)
├── infra/
│   └── README.md           # AWS deployment notes
├── docker-compose.yml      # postgres:16 + redis:7 + backend
├── .env.example            # root-level convenience env (optional)
├── .gitignore
├── README.md               # you are here
└── SETUP.md                # step-by-step onboarding checklist
```

---

## Quickstart — backend

> Prereqs: Node.js 20+, Docker + Docker Compose, and (for local-only DB) `psql`.

```bash
# 1. From the repo root, copy env placeholders and fill in real values.
cp apps/backend/.env.example apps/backend/.env
#    Edit apps/backend/.env — set GEMINI_API_KEY, JWT secrets, DB creds, AWS, Firebase.

# 2. Bring up Postgres + Redis + backend (Postgres auto-runs database/schema.sql on first boot).
docker-compose up -d

# 3. (If you run the API outside Docker) apply migrations against the running DB.
cd apps/backend
npm install
npm run migration:run        # TypeORM migrations on top of the base schema

# 4. Start the API in watch mode for local development.
npm run start:dev            # http://localhost:3000 (see PORT in .env)
```

- `docker-compose up -d` starts `postgres:16`, `redis:7`, and the backend image built from
  `apps/backend`. On first boot Postgres initializes from `database/schema.sql`.
- To run the API directly on the host instead of in a container, leave the backend service
  out (`docker-compose up -d postgres redis`) and run `npm run start:dev` locally.
- Health check once running: `curl http://localhost:3000/health`.

See [`SETUP.md`](SETUP.md) for the full first-time checklist (Firebase, AWS, IAP, OS permissions).

---

## Quickstart — Flutter mobile

> Prereqs: Flutter SDK (stable channel), Android Studio / Xcode toolchains, a configured
> Firebase project (see [`SETUP.md`](SETUP.md)).

```bash
cd apps/mobile

# 1. Fetch dependencies.
flutter pub get

# 2. Generate code (json_serializable, freezed, retrofit, etc.).
dart run build_runner build --delete-conflicting-outputs

# 3. Run against your backend. API_BASE_URL is injected at build time via --dart-define.
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
#   Android emulator → host is 10.0.2.2 ; iOS simulator → http://localhost:3000 ;
#   physical device → your machine's LAN IP, e.g. http://192.168.1.20:3000
```

- Drop `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in place before
  running — these are git-ignored. See [`SETUP.md`](SETUP.md).
- For release builds, pass the production URL:
  `flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com`.

---

## Security

> **Rotate any leaked Gemini key immediately.** If a `GEMINI_API_KEY` has ever appeared in a
> commit, screenshot, log, chat, or the Flutter app, treat it as compromised: revoke it in
> Google AI Studio / Google Cloud and issue a fresh one.

Non-negotiable rules for this codebase:

- **Keys live only in the backend environment.** `GEMINI_API_KEY` is read solely from
  `process.env.GEMINI_API_KEY` on the server. It is **never** bundled into, hardcoded in, or
  sent to the Flutter app. The app reaches Gemini *only* through authenticated backend
  endpoints.
- **No secrets in git.** `.env`, service-account JSON, keystores, and `*.plist` credentials
  are git-ignored. Commit only `*.env.example` with placeholders.
- **Passwords** are hashed with argon2 (bcrypt fallback). **Refresh tokens** are stored hashed.
- **Input validation** everywhere via class-validator DTOs; all DB access uses parameterized
  queries through TypeORM.
- **Transport & edge hardening:** helmet, a CORS allowlist, and `ThrottlerGuard` rate limiting
  are enabled on the API.
- **Media** is served from a private S3 bucket via short-TTL presigned URLs only.
- **Premium is server-authoritative:** store receipts are validated server-side; the client is
  never trusted to grant entitlements.

---

## Further docs

- [`SETUP.md`](SETUP.md) — first-time setup checklist (env, Firebase, AWS, IAP, OS permissions).
- [`infra/README.md`](infra/README.md) — AWS deployment architecture and CI/CD.
- [`database/schema.sql`](database/schema.sql) — Postgres schema.
