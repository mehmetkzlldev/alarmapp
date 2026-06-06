import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Creates the `daily_ai_missions` table backing the AI-mission feature.
 *
 * One AI-generated wake-up mission per user per local calendar day.
 * UNIQUE(user_id, date) makes generation idempotent across the scheduler and
 * the lazy on-demand path.
 *
 * The high timestamp prefix ensures this runs AFTER the base schema migration
 * (which creates `users` and enables `pgcrypto` for gen_random_uuid()).
 */
export class CreateDailyAiMissions1717600000000 implements MigrationInterface {
  name = 'CreateDailyAiMissions1717600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // gen_random_uuid() comes from pgcrypto; ensure it exists (idempotent).
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto"`);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "daily_ai_missions" (
        "id"                 uuid         NOT NULL DEFAULT gen_random_uuid(),
        "user_id"            uuid         NOT NULL,
        "date"               date         NOT NULL,
        "mission_type"       varchar      NOT NULL,
        "difficulty"         varchar      NOT NULL DEFAULT 'medium',
        "instruction"        text         NOT NULL,
        "target_object"      varchar      NULL,
        "generated_content"  jsonb        NOT NULL DEFAULT '{}',
        "status"             varchar      NOT NULL DEFAULT 'assigned',
        "gemini_request_id"  varchar      NULL,
        "completed_at"       timestamptz  NULL,
        "created_at"         timestamptz  NOT NULL DEFAULT now(),
        CONSTRAINT "pk_daily_ai_missions" PRIMARY KEY ("id"),
        CONSTRAINT "uq_daily_ai_missions_user_date" UNIQUE ("user_id", "date"),
        CONSTRAINT "fk_daily_ai_missions_user"
          FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE,
        CONSTRAINT "chk_daily_ai_missions_status"
          CHECK ("status" IN ('assigned', 'completed', 'expired')),
        CONSTRAINT "chk_daily_ai_missions_difficulty"
          CHECK ("difficulty" IN ('easy', 'medium', 'hard'))
      )
    `);

    // Lookups are always (user_id, date); the unique constraint already provides
    // a usable index, but an explicit index documents the access pattern.
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_daily_ai_missions_user_date"
        ON "daily_ai_missions" ("user_id", "date")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "idx_daily_ai_missions_user_date"`,
    );
    await queryRunner.query(`DROP TABLE IF EXISTS "daily_ai_missions"`);
  }
}
