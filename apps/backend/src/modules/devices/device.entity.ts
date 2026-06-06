import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/user.entity';

/** Device platform. Mirrors devices.platform CHECK constraint. */
export type DevicePlatform = 'ios' | 'android';

/**
 * Canonical `devices` table.
 *
 * One row per (user, fcm_token). The composite UNIQUE(user_id, fcm_token) lets us
 * upsert idempotently when the same device re-registers (e.g. app reopen / token
 * refresh) without creating duplicates.
 */
@Entity({ name: 'devices' })
@Unique('uq_devices_user_fcm', ['userId', 'fcmToken'])
@Index('idx_devices_user_id', ['userId'])
export class Device {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'fcm_token', type: 'varchar' })
  fcmToken: string;

  @Column({ type: 'varchar' })
  platform: DevicePlatform;

  @Column({ name: 'app_version', type: 'varchar', nullable: true })
  appVersion: string | null;

  @Column({ name: 'last_active_at', type: 'timestamptz', nullable: true })
  lastActiveAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
