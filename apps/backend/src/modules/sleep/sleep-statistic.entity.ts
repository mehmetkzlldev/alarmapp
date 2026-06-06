import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

/**
 * Maps to the canonical `sleep_statistics` table.
 * One row per (user, date). `date` is a calendar date (no time component).
 */
@Entity({ name: 'sleep_statistics' })
@Index('uq_sleep_statistics_user_date', ['userId', 'date'], { unique: true })
export class SleepStatistic {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ type: 'date' })
  date: string; // 'YYYY-MM-DD'

  @Column({ name: 'bedtime_at', type: 'timestamptz', nullable: true })
  bedtimeAt: Date | null;

  @Column({ name: 'sleep_at', type: 'timestamptz', nullable: true })
  sleepAt: Date | null;

  @Column({ name: 'wake_at', type: 'timestamptz', nullable: true })
  wakeAt: Date | null;

  @Column({ name: 'duration_min', type: 'int', nullable: true })
  durationMin: number | null;

  @Column({ name: 'quality_score', type: 'smallint', nullable: true })
  qualityScore: number | null;

  @Column({
    name: 'mission_success_rate',
    type: 'numeric',
    precision: 5,
    scale: 2,
    nullable: true,
  })
  missionSuccessRate: string | null; // numeric returned as string by pg driver

  @Column({ name: 'snooze_count', type: 'smallint', default: 0 })
  snoozeCount: number;

  @Column({ type: 'varchar', default: 'alarm' })
  source: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
