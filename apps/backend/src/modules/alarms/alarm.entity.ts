import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { AlarmMission } from './alarm-mission.entity';

/**
 * Alarm entity — maps to the `alarms` table.
 *
 * Notes on column types:
 * - `time` is a wall-clock time (no date) stored as a Postgres `time` column. It is
 *   interpreted in the alarm's own `timezone`, NOT the server timezone.
 * - `repeat_days` is a Postgres smallint[] where each element is a weekday index.
 *   Convention: 0 = Sunday ... 6 = Saturday. An empty array means a one-shot alarm.
 * - `next_trigger_at` is a fully-resolved UTC instant computed by AlarmsService from
 *   (time + timezone + repeat_days). It is what the scheduler/notification worker reads.
 */
@Entity({ name: 'alarms' })
@Index('idx_alarms_user_id', ['userId'])
// Partial-ish index hint for the scheduler: active, non-deleted alarms ordered by trigger.
@Index('idx_alarms_next_trigger_at', ['nextTriggerAt'])
export class Alarm {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  // No inverse property declared on User (the canonical User entity only exposes
  // `refreshTokens`), so we use the unidirectional ManyToOne form here.
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', default: 'Alarm' })
  label: string;

  /** Wall-clock time (HH:mm:ss) in the alarm's timezone. */
  @Column({ type: 'time' })
  time: string;

  @Column({ type: 'varchar', default: 'UTC' })
  timezone: string;

  /**
   * Weekday indices to repeat on (0=Sun..6=Sat). Empty => fires once then deactivates.
   * Stored as Postgres smallint[].
   */
  @Column({
    name: 'repeat_days',
    type: 'smallint',
    array: true,
    default: () => "'{}'",
  })
  repeatDays: number[];

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'varchar', default: 'default' })
  sound: string;

  @Column({ type: 'boolean', default: true })
  vibration: boolean;

  /** 0..100 */
  @Column({ type: 'smallint', default: 80 })
  volume: number;

  @Column({ name: 'gradual_volume', type: 'boolean', default: false })
  gradualVolume: boolean;

  @Column({ name: 'snooze_enabled', type: 'boolean', default: true })
  snoozeEnabled: boolean;

  @Column({ name: 'snooze_interval_min', type: 'smallint', default: 5 })
  snoozeIntervalMin: number;

  @Column({ name: 'snooze_limit', type: 'smallint', default: 3 })
  snoozeLimit: number;

  /** Resolved UTC instant for the next fire. Null when inactive / no upcoming trigger. */
  @Column({ name: 'next_trigger_at', type: 'timestamptz', nullable: true })
  nextTriggerAt: Date | null;

  @OneToMany(() => AlarmMission, (mission) => mission.alarm, {
    cascade: true,
  })
  missions: AlarmMission[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;
}
