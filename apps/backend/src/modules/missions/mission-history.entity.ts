import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Alarm } from '../alarms/alarm.entity';
import { AlarmMission } from '../alarms/alarm-mission.entity';

/**
 * MissionHistory entity — maps to the `mission_history` table.
 *
 * Append-only audit of every mission attempt outcome. Used to drive sleep statistics,
 * difficulty tuning, and the AI-mission feedback loop.
 *
 * The alarm / alarm_mission FKs are nullable + ON DELETE SET NULL so history survives
 * the deletion of the originating alarm.
 */
@Entity({ name: 'mission_history' })
@Index('idx_mission_history_user_id', ['userId'])
@Index('idx_mission_history_user_created', ['userId', 'createdAt'])
export class MissionHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  // Unidirectional: the canonical User entity does not declare a `missionHistory`
  // inverse relation, so we keep this side authoritative.
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'alarm_id', type: 'uuid', nullable: true })
  alarmId: string | null;

  @ManyToOne(() => Alarm, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'alarm_id' })
  alarm?: Alarm | null;

  @Column({ name: 'alarm_mission_id', type: 'uuid', nullable: true })
  alarmMissionId: string | null;

  @ManyToOne(() => AlarmMission, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'alarm_mission_id' })
  alarmMission?: AlarmMission | null;

  @Column({ name: 'mission_type', type: 'varchar' })
  missionType: string;

  /** success | failed | skipped */
  @Column({ type: 'varchar' })
  status: string;

  @Column({ name: 'attempts_count', type: 'smallint', default: 1 })
  attemptsCount: number;

  @Column({ name: 'duration_sec', type: 'int', nullable: true })
  durationSec: number | null;

  @Column({ type: 'varchar', nullable: true })
  difficulty: string | null;

  @Column({ type: 'jsonb', default: () => "'{}'" })
  metadata: Record<string, unknown>;

  @Column({ name: 'image_s3_key', type: 'varchar', nullable: true })
  imageS3Key: string | null;

  /** AI detection confidence 0..1, stored numeric(5,4). */
  @Column({
    type: 'numeric',
    precision: 5,
    scale: 4,
    nullable: true,
    transformer: {
      to: (v?: number | null) => v ?? null,
      from: (v?: string | null) => (v == null ? null : parseFloat(v)),
    },
  })
  confidence: number | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
