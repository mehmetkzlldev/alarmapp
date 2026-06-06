import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

export type DailyAiMissionStatus = 'assigned' | 'completed' | 'expired';

/**
 * daily_ai_missions — one AI-generated wake-up mission per user per local day.
 *
 * UNIQUE(user_id, date) guarantees idempotent generation: the scheduler and the
 * on-demand GET both upsert against this constraint so a user never gets two
 * missions for the same calendar day (in their timezone).
 */
@Entity({ name: 'daily_ai_missions' })
@Unique('uq_daily_ai_missions_user_date', ['userId', 'date'])
export class DailyAiMission {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  /** Local calendar date (in the user's timezone) this mission belongs to. */
  @Column({ type: 'date' })
  date!: string; // YYYY-MM-DD

  // One of: math | shake | object_detection | memory | typing | qr
  @Column({ name: 'mission_type', type: 'varchar' })
  missionType!: string;

  // easy | medium | hard
  @Column({ type: 'varchar', default: 'medium' })
  difficulty!: string;

  @Column({ type: 'text' })
  instruction!: string;

  /** Present for object-detection style missions (one of SUPPORTED_OBJECTS). */
  @Column({ name: 'target_object', type: 'varchar', nullable: true })
  targetObject!: string | null;

  /** Full raw payload returned by Gemini, for auditing/regeneration. */
  @Column({ name: 'generated_content', type: 'jsonb', default: {} })
  generatedContent!: Record<string, unknown>;

  // assigned | completed | expired
  @Column({ type: 'varchar', default: 'assigned' })
  status!: DailyAiMissionStatus;

  @Column({ name: 'gemini_request_id', type: 'varchar', nullable: true })
  geminiRequestId!: string | null;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt!: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
