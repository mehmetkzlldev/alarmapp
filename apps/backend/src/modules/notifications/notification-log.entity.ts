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
import { Device } from '../devices/device.entity';

/**
 * Lifecycle of a notification row.
 * queued    -> created, waiting for the BullMQ worker
 * sent      -> handed off to FCM successfully (fcm_message_id populated)
 * delivered -> (optional) confirmed delivered via FCM delivery receipts/webhooks
 * failed    -> FCM rejected the send (error populated)
 * read      -> user opened/acknowledged it (read_at populated)
 */
export type NotificationStatus =
  | 'queued'
  | 'sent'
  | 'delivered'
  | 'failed'
  | 'read';

/** Maps to the canonical `notification_logs` table. */
@Entity({ name: 'notification_logs' })
export class NotificationLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_notification_logs_user_id')
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'device_id', type: 'uuid', nullable: true })
  deviceId: string | null;

  // ON DELETE SET NULL per the canonical model.
  @ManyToOne(() => Device, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'device_id' })
  device?: Device | null;

  @Column({ type: 'varchar' })
  type: string;

  @Column({ type: 'varchar', nullable: true })
  title: string | null;

  @Column({ type: 'text', nullable: true })
  body: string | null;

  @Column({ type: 'jsonb', default: {} })
  data: Record<string, unknown>;

  @Column({ type: 'varchar', default: 'push' })
  channel: string;

  @Index('idx_notification_logs_status')
  @Column({ type: 'varchar', default: 'queued' })
  status: NotificationStatus;

  @Column({ name: 'fcm_message_id', type: 'varchar', nullable: true })
  fcmMessageId: string | null;

  @Column({ type: 'varchar', nullable: true })
  error: string | null;

  @Column({ name: 'scheduled_at', type: 'timestamptz', nullable: true })
  scheduledAt: Date | null;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt: Date | null;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
