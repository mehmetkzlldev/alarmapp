-- =============================================================================
-- AI Alarm Clock App (Alarmy-style) — PostgreSQL Schema
-- =============================================================================
-- Production-ready DDL.
--   * snake_case identifiers
--   * all PKs are UUID (gen_random_uuid())
--   * all tables have created_at; mutable tables also have updated_at
--   * enum-like varchars enforced with CHECK constraints (cheaper to evolve
--     than native ENUM types — no ALTER TYPE migrations required)
--   * idempotent-friendly: CREATE EXTENSION IF NOT EXISTS, CREATE TABLE IF NOT
--     EXISTS, CREATE INDEX IF NOT EXISTS, seed via ON CONFLICT DO NOTHING.
--
-- Apply with:  psql "$DATABASE_URL" -f database/schema.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Extensions
-- -----------------------------------------------------------------------------
-- pgcrypto provides gen_random_uuid().
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
-- citext provides case-insensitive text (used for email uniqueness).
CREATE EXTENSION IF NOT EXISTS "citext";


-- -----------------------------------------------------------------------------
-- Shared trigger function: auto-maintain updated_at on UPDATE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- TABLES (created in dependency order)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    email           citext        NOT NULL,
    password_hash   varchar       NULL,                 -- null for social-only accounts
    firebase_uid    varchar       NULL,
    auth_provider   varchar       NOT NULL DEFAULT 'email',
    display_name    varchar       NULL,
    avatar_url      varchar       NULL,
    email_verified  boolean       NOT NULL DEFAULT false,
    role            varchar       NOT NULL DEFAULT 'user',
    timezone        varchar       NOT NULL DEFAULT 'UTC',
    locale          varchar       NOT NULL DEFAULT 'en',
    is_premium      boolean       NOT NULL DEFAULT false,
    premium_until   timestamptz   NULL,
    status          varchar       NOT NULL DEFAULT 'active',
    created_at      timestamptz   NOT NULL DEFAULT now(),
    updated_at      timestamptz   NOT NULL DEFAULT now(),
    deleted_at      timestamptz   NULL,

    CONSTRAINT users_email_unique        UNIQUE (email),
    CONSTRAINT users_firebase_uid_unique UNIQUE (firebase_uid),
    CONSTRAINT users_auth_provider_check CHECK (auth_provider IN ('email', 'google', 'apple')),
    CONSTRAINT users_role_check          CHECK (role IN ('user', 'admin')),
    CONSTRAINT users_status_check         CHECK (status IN ('active', 'suspended', 'deleted'))
);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- refresh_tokens  (one row per issued refresh token; token stored HASHED)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  varchar       NOT NULL,                 -- sha256/argon2 hash, never the raw token
    expires_at  timestamptz   NOT NULL,
    revoked_at  timestamptz   NULL,
    user_agent  varchar       NULL,
    ip          varchar       NULL,
    created_at  timestamptz   NOT NULL DEFAULT now()
);


-- -----------------------------------------------------------------------------
-- devices  (FCM push targets; a user may have many devices)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS devices (
    id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token       varchar       NOT NULL,
    platform        varchar       NULL,
    app_version     varchar       NULL,
    last_active_at  timestamptz   NULL,
    created_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT devices_platform_check       CHECK (platform IS NULL OR platform IN ('ios', 'android')),
    CONSTRAINT devices_user_fcm_token_unique UNIQUE (user_id, fcm_token)
);


-- -----------------------------------------------------------------------------
-- alarms
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alarms (
    id                  uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label               varchar       NOT NULL DEFAULT 'Alarm',
    time                time          NOT NULL,
    timezone            varchar       NOT NULL DEFAULT 'UTC',
    repeat_days         smallint[]    NOT NULL DEFAULT '{}',  -- 0=Sun .. 6=Sat
    is_active           boolean       NOT NULL DEFAULT true,
    sound               varchar       NOT NULL DEFAULT 'default',
    vibration           boolean       NOT NULL DEFAULT true,
    volume              smallint      NOT NULL DEFAULT 80,
    gradual_volume      boolean       NOT NULL DEFAULT false,
    snooze_enabled      boolean       NOT NULL DEFAULT true,
    snooze_interval_min smallint      NOT NULL DEFAULT 5,
    snooze_limit        smallint      NOT NULL DEFAULT 3,
    next_trigger_at     timestamptz   NULL,
    created_at          timestamptz   NOT NULL DEFAULT now(),
    updated_at          timestamptz   NOT NULL DEFAULT now(),
    deleted_at          timestamptz   NULL,

    CONSTRAINT alarms_volume_check        CHECK (volume BETWEEN 0 AND 100),
    CONSTRAINT alarms_snooze_interval_check CHECK (snooze_interval_min BETWEEN 1 AND 60),
    CONSTRAINT alarms_snooze_limit_check   CHECK (snooze_limit BETWEEN 0 AND 20)
);

CREATE TRIGGER trg_alarms_updated_at
    BEFORE UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- mission_types  (catalog of dismissal-mission kinds; seeded below)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mission_types (
    id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    code            varchar       NOT NULL,
    name            varchar       NOT NULL,
    description     text          NULL,
    is_premium      boolean       NOT NULL DEFAULT false,
    default_config  jsonb         NOT NULL DEFAULT '{}',
    created_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT mission_types_code_unique UNIQUE (code),
    CONSTRAINT mission_types_code_check  CHECK (code IN ('math', 'shake', 'object_detection', 'memory', 'typing', 'qr'))
);


-- -----------------------------------------------------------------------------
-- alarm_missions  (ordered missions attached to an alarm)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS alarm_missions (
    id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    alarm_id      uuid          NOT NULL REFERENCES alarms(id) ON DELETE CASCADE,
    -- references the catalog code; FK guarantees only valid mission types are used
    mission_type  varchar       NOT NULL REFERENCES mission_types(code),
    order_index   smallint      NOT NULL DEFAULT 0,
    difficulty    varchar       NOT NULL DEFAULT 'medium',
    config        jsonb         NOT NULL DEFAULT '{}',
    created_at    timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT alarm_missions_difficulty_check  CHECK (difficulty IN ('easy', 'medium', 'hard')),
    CONSTRAINT alarm_missions_alarm_order_unique UNIQUE (alarm_id, order_index)
);


-- -----------------------------------------------------------------------------
-- mission_history  (per-attempt record of mission outcomes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mission_history (
    id                uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- keep history even if the alarm / mission definition is later deleted
    alarm_id          uuid          NULL REFERENCES alarms(id) ON DELETE SET NULL,
    alarm_mission_id  uuid          NULL REFERENCES alarm_missions(id) ON DELETE SET NULL,
    mission_type      varchar       NOT NULL,           -- denormalized snapshot for analytics
    status            varchar       NOT NULL,
    attempts_count    smallint      NOT NULL DEFAULT 1,
    duration_sec      int           NULL,
    difficulty        varchar       NULL,
    metadata          jsonb         NOT NULL DEFAULT '{}',
    image_s3_key      varchar       NULL,               -- object_detection: private S3 key (presigned at read time)
    confidence        numeric(5,4)  NULL,               -- AI detection confidence 0.0000–1.0000
    created_at        timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT mission_history_status_check     CHECK (status IN ('success', 'failed', 'skipped')),
    CONSTRAINT mission_history_difficulty_check CHECK (difficulty IS NULL OR difficulty IN ('easy', 'medium', 'hard')),
    CONSTRAINT mission_history_confidence_check CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1))
);


-- -----------------------------------------------------------------------------
-- subscriptions  (1:1 with users; server-validated store entitlement)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
    id                       uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan                     varchar       NOT NULL DEFAULT 'free',
    store                    varchar       NULL,
    store_subscription_id    varchar       NULL,
    original_transaction_id  varchar       NULL,
    status                   varchar       NOT NULL DEFAULT 'inactive',
    started_at               timestamptz   NULL,
    current_period_end       timestamptz   NULL,
    auto_renew               boolean       NOT NULL DEFAULT true,
    latest_receipt           jsonb         NULL,        -- last verified store receipt payload
    created_at               timestamptz   NOT NULL DEFAULT now(),
    updated_at               timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT subscriptions_user_unique  UNIQUE (user_id),
    CONSTRAINT subscriptions_plan_check   CHECK (plan IN ('free', 'premium_monthly', 'premium_yearly')),
    CONSTRAINT subscriptions_store_check  CHECK (store IS NULL OR store IN ('app_store', 'play_store')),
    CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'expired', 'cancelled', 'grace_period', 'trial', 'inactive'))
);

CREATE TRIGGER trg_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- -----------------------------------------------------------------------------
-- notification_logs  (delivery audit trail for push / other channels)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_logs (
    id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id       uuid          NULL REFERENCES devices(id) ON DELETE SET NULL,
    type            varchar       NOT NULL,             -- e.g. 'alarm', 'reminder', 'marketing'
    title           varchar       NULL,
    body            text          NULL,
    data            jsonb         NOT NULL DEFAULT '{}',
    channel         varchar       NOT NULL DEFAULT 'push',
    status          varchar       NOT NULL DEFAULT 'queued',
    fcm_message_id  varchar       NULL,
    error           varchar       NULL,
    scheduled_at    timestamptz   NULL,
    sent_at         timestamptz   NULL,
    read_at         timestamptz   NULL,
    created_at      timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT notification_logs_status_check CHECK (status IN ('queued', 'sent', 'delivered', 'failed', 'read'))
);


-- -----------------------------------------------------------------------------
-- sleep_statistics  (one aggregated row per user per calendar date)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sleep_statistics (
    id                    uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               uuid          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date                  date          NOT NULL,
    bedtime_at            timestamptz   NULL,
    sleep_at              timestamptz   NULL,
    wake_at               timestamptz   NULL,
    duration_min          int           NULL,
    quality_score         smallint      NULL,           -- 0–100
    mission_success_rate  numeric(5,2)  NULL,           -- percentage 0.00–100.00
    snooze_count          smallint      NOT NULL DEFAULT 0,
    source                varchar       NOT NULL DEFAULT 'alarm',
    created_at            timestamptz   NOT NULL DEFAULT now(),
    updated_at            timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT sleep_statistics_user_date_unique  UNIQUE (user_id, date),
    CONSTRAINT sleep_statistics_quality_check     CHECK (quality_score IS NULL OR quality_score BETWEEN 0 AND 100),
    CONSTRAINT sleep_statistics_success_rate_check CHECK (mission_success_rate IS NULL OR (mission_success_rate >= 0 AND mission_success_rate <= 100))
);

CREATE TRIGGER trg_sleep_statistics_updated_at
    BEFORE UPDATE ON sleep_statistics
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- INDEXES
-- =============================================================================

-- users -----------------------------------------------------------------------
-- Active-account email lookups (login). Partial: ignore soft-deleted rows.
CREATE INDEX IF NOT EXISTS idx_users_email_active
    ON users (email) WHERE deleted_at IS NULL;

-- refresh_tokens --------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id
    ON refresh_tokens (user_id);
-- Fast rotation/validation by hash, only for live (non-revoked) tokens.
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash
    ON refresh_tokens (token_hash) WHERE revoked_at IS NULL;

-- devices ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_devices_user_id
    ON devices (user_id);

-- alarms ----------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_alarms_user_id
    ON alarms (user_id);
-- Scheduler hot path: find due, active alarms. Partial keeps it tiny.
CREATE INDEX IF NOT EXISTS idx_alarms_next_trigger_active
    ON alarms (next_trigger_at) WHERE is_active = true AND deleted_at IS NULL;

-- alarm_missions --------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_alarm_missions_alarm_id
    ON alarm_missions (alarm_id);
CREATE INDEX IF NOT EXISTS idx_alarm_missions_mission_type
    ON alarm_missions (mission_type);

-- mission_history -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mission_history_user_id
    ON mission_history (user_id);
-- Per-user timeline / analytics queries.
CREATE INDEX IF NOT EXISTS idx_mission_history_user_created
    ON mission_history (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mission_history_alarm_id
    ON mission_history (alarm_id);
CREATE INDEX IF NOT EXISTS idx_mission_history_alarm_mission_id
    ON mission_history (alarm_mission_id);

-- subscriptions ---------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id
    ON subscriptions (user_id);
-- Renewal / expiry sweep job scans by period end.
CREATE INDEX IF NOT EXISTS idx_subscriptions_current_period_end
    ON subscriptions (current_period_end);

-- notification_logs -----------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id
    ON notification_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_device_id
    ON notification_logs (device_id);
-- Dashboard filters like "failed pushes for user X".
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_status
    ON notification_logs (user_id, status);

-- sleep_statistics ------------------------------------------------------------
-- Composite covers per-user date-range charts; ordered DESC for recent-first.
CREATE INDEX IF NOT EXISTS idx_sleep_statistics_user_date
    ON sleep_statistics (user_id, date DESC);


-- =============================================================================
-- SEED DATA — mission_types catalog
-- =============================================================================
-- Idempotent via ON CONFLICT on the unique code.
INSERT INTO mission_types (code, name, description, is_premium, default_config) VALUES
    ('math',
     'Math Problems',
     'Solve arithmetic problems to dismiss the alarm.',
     false,
     '{"problem_count": 3, "operations": ["add", "subtract", "multiply"]}'),
    ('shake',
     'Shake Phone',
     'Shake your phone vigorously to dismiss the alarm.',
     false,
     '{"shake_count": 30}'),
    ('object_detection',
     'Photograph an Object',
     'Take a photo of a specific object (e.g. sink, toothbrush). Verified by AI.',
     true,
     '{"target": "sink", "min_confidence": 0.6}'),
    ('memory',
     'Memory Match',
     'Memorize and reproduce a pattern to dismiss the alarm.',
     false,
     '{"grid_size": 3, "rounds": 3}'),
    ('typing',
     'Typing Challenge',
     'Type the given phrase exactly to dismiss the alarm.',
     false,
     '{"phrase_count": 1, "min_length": 20}'),
    ('qr',
     'Scan QR / Barcode',
     'Scan a pre-registered QR or barcode (e.g. on the bathroom mirror).',
     true,
     '{"require_registered_code": true}')
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- End of schema
-- =============================================================================
