# Setup checklist

First-time setup for the Alarmy-style AI alarm clock. Follow the numbered steps in order.
Tick each box as you go. Steps marked **(prod)** are only needed for staging/production.

> **Golden rule:** secrets live in `apps/backend/.env` (git-ignored) and in your cloud
> secrets manager — never in git, never in the Flutter app. The `GEMINI_API_KEY` is used by
> the **backend only**.

---

## 0. Prerequisites

- [ ] **Node.js 20+** and **npm** (for the backend)
- [ ] **Docker + Docker Compose** (for local Postgres/Redis/backend)
- [ ] **Flutter SDK** (stable channel) with Android Studio and/or Xcode toolchains
- [ ] **PostgreSQL client** (`psql`) — optional, for manual schema loading
- [ ] Accounts: **Google AI Studio / Google Cloud** (Gemini + Firebase), **AWS** (S3),
      **Apple Developer** and/or **Google Play Console** (for IAP)

---

## 1. Provision Postgres + Redis

**Option A — Docker (recommended for local dev):**

- [ ] From the repo root, run only the data services for now:
  ```bash
  docker-compose up -d postgres redis
  ```
- [ ] Confirm both are healthy: `docker-compose ps` (status should be `healthy`).
- [ ] On first boot, Postgres auto-applies `database/schema.sql`. (See step 4 to re-apply.)

**Option B — Managed / existing servers:**

- [ ] Create a Postgres 16 database and a Redis 7 instance.
- [ ] Record host, port, database name, username, and password for step 2.

---

## 2. Configure the backend `.env`

- [ ] Copy the template:
  ```bash
  cp apps/backend/.env.example apps/backend/.env
  ```
- [ ] Fill in **`apps/backend/.env`** (never commit it). At minimum:
  - [ ] `NODE_ENV`, `PORT`
  - [ ] `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`
  - [ ] `REDIS_HOST`, `REDIS_PORT`
  - [ ] `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` — generate strong unique values:
    ```bash
    node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
    ```
  - [ ] `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL`
  - [ ] `CORS_ORIGINS` — comma-separated allowlist (e.g. your app/web origins)
  - [ ] **`GEMINI_API_KEY`** — a **fresh** key from Google AI Studio (see step 3)
  - [ ] Firebase service-account values (see step 5)
  - [ ] AWS S3 values (see step 6)
  - [ ] Store/IAP values (see step 8)

---

## 3. Create a fresh Gemini API key

- [ ] In **Google AI Studio** (or Google Cloud → Generative Language API), create a new API key.
- [ ] Restrict it (API restriction = Generative Language API; add IP/referrer limits where possible).
- [ ] Put it in `apps/backend/.env` as `GEMINI_API_KEY=...`.
- [ ] **If any old key was ever exposed** (git, logs, screenshots, the app), **revoke it now**
      and use the new one. The key is read only via `process.env.GEMINI_API_KEY` on the server.

---

## 4. Load the database schema

- [ ] **Docker, first boot:** nothing to do — `database/schema.sql` was applied automatically.
- [ ] **Re-apply after schema changes (Docker):**
  ```bash
  docker-compose down -v && docker-compose up -d postgres redis   # wipes & reinitializes
  ```
- [ ] **Manual / managed DB:**
  ```bash
  psql "postgresql://USER:PASSWORD@HOST:PORT/DBNAME" -f database/schema.sql
  ```
- [ ] **Run migrations** (TypeORM changes layered on top of the base schema):
  ```bash
  cd apps/backend && npm install && npm run migration:run
  ```
- [ ] Start the API: `npm run start:dev` (or `docker-compose up -d backend`) and hit
      `GET /health`.

---

## 5. Configure Firebase (push + Flutter)

- [ ] In the **Firebase console**, create (or select) a project.
- [ ] **Backend (Admin SDK):** Project settings → Service accounts → *Generate new private key*.
      Download the JSON. Provide it to the backend via env (e.g. `FIREBASE_SERVICE_ACCOUNT_JSON`
      as a path or base64 blob, per `.env.example`). **Do not commit the JSON** (git-ignored).
- [ ] **Android client:** add an Android app (package name = the app's `applicationId`),
      download **`google-services.json`** → place in `apps/mobile/android/app/`.
- [ ] **iOS client:** add an iOS app (bundle ID), download **`GoogleService-Info.plist`** →
      place in `apps/mobile/ios/Runner/` (add to the Runner target in Xcode).
- [ ] Enable **Cloud Messaging (FCM)** in the Firebase project.

---

## 6. Configure AWS S3 (media storage)

- [ ] Create a **private** S3 bucket (Block Public Access = ON).
- [ ] Create an **IAM user/role** scoped to that bucket only (`s3:GetObject`, `s3:PutObject`,
      `s3:DeleteObject` on `arn:aws:s3:::your-bucket/*`).
- [ ] Add to `apps/backend/.env`: `AWS_REGION`, `S3_BUCKET`, `AWS_ACCESS_KEY_ID`,
      `AWS_SECRET_ACCESS_KEY` (or use an instance role in prod).
- [ ] Confirm uploads/downloads work via **short-TTL presigned URLs** only — clients never get
      direct bucket access.

---

## 7. Run the apps end-to-end

- [ ] Backend up (Docker or host) and `GET /health` returns 200.
- [ ] Flutter:
  ```bash
  cd apps/mobile
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator host
  ```
  - iOS simulator: `--dart-define=API_BASE_URL=http://localhost:3000`
  - Physical device: use your machine's LAN IP.
- [ ] Register/log in, create an alarm, and verify it syncs to the backend.

---

## 8. Configure in-app purchases (IAP)

- [ ] **Google Play Console:** create subscription/products; note the product IDs.
- [ ] **App Store Connect:** create the matching auto-renewable subscriptions; note product IDs.
- [ ] Put product IDs / shared secrets in `apps/backend/.env` (per `.env.example`).
- [ ] Verify the backend **validates receipts server-side** (Play Developer API / App Store
      verifyReceipt or App Store Server API). The client never grants premium directly.

---

## 9. Android — exact alarms & battery exemptions

- [ ] Declare the exact-alarm permission in `apps/mobile/android/app/src/main/AndroidManifest.xml`:
      `SCHEDULE_EXACT_ALARM` (Android 12) / `USE_EXACT_ALARM` (Android 13+ alarm-clock apps).
- [ ] Add `POST_NOTIFICATIONS` (Android 13+) and `WAKE_LOCK`.
- [ ] At runtime, on Android 12+, route the user to grant *Alarms & reminders* if
      `canScheduleExactAlarms()` is false.
- [ ] Prompt the user to **ignore battery optimizations** (request
      `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) so alarms fire reliably in Doze.

---

## 10. iOS — critical alert entitlement

- [ ] Critical alerts require a special entitlement from Apple — **request it** at
      <https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement>.
- [ ] Once granted, add the `com.apple.developer.usernotifications.critical-alerts`
      entitlement to the Runner target and request critical-alert authorization at runtime.
- [ ] Enable **Background Modes** (Remote notifications) and configure notification
      categories/sounds for the alarm experience.

---

## 11. (prod) Production hardening

- [ ] Store all secrets in **AWS Secrets Manager** (or equivalent) — not in `.env` files.
- [ ] Tighten `CORS_ORIGINS`, confirm helmet + `ThrottlerGuard` rate limits are active.
- [ ] Use a managed Postgres (Multi-AZ) and Redis; enable backups and TLS.
- [ ] Put the API behind CloudFront + WAF. See [`infra/README.md`](infra/README.md).

---

### Done

You should now have: data services running, schema + migrations applied, backend healthy,
Firebase/AWS/IAP wired, and the Flutter app talking to the API. If anything fails, check
`docker-compose logs -f` and confirm `apps/backend/.env` is complete.
