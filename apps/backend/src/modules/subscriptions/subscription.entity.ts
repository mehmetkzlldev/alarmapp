import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export type SubscriptionPlan = 'free' | 'premium_monthly' | 'premium_yearly';
export type SubscriptionStore = 'app_store' | 'play_store';
export type SubscriptionStatus =
  | 'active'
  | 'expired'
  | 'cancelled'
  | 'grace_period'
  | 'trial'
  | 'inactive';

/**
 * Maps to the canonical `subscriptions` table (1:1 with users).
 *
 * `originalTransactionId` is the cross-renewal stable identifier from the store
 * (Apple: original_transaction_id; Google: derived from the order id). We use it
 * as the idempotency key for receipt validation so the same purchase can be
 * re-validated without creating duplicate state changes.
 */
@Entity({ name: 'subscriptions' })
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('uq_subscriptions_user_id', { unique: true })
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ type: 'varchar', default: 'free' })
  plan: SubscriptionPlan;

  @Column({ type: 'varchar', nullable: true })
  store: SubscriptionStore | null;

  @Column({ name: 'store_subscription_id', type: 'varchar', nullable: true })
  storeSubscriptionId: string | null;

  @Index('idx_subscriptions_original_transaction_id')
  @Column({
    name: 'original_transaction_id',
    type: 'varchar',
    nullable: true,
  })
  originalTransactionId: string | null;

  @Column({ type: 'varchar', default: 'inactive' })
  status: SubscriptionStatus;

  @Column({ name: 'started_at', type: 'timestamptz', nullable: true })
  startedAt: Date | null;

  @Column({ name: 'current_period_end', type: 'timestamptz', nullable: true })
  currentPeriodEnd: Date | null;

  @Column({ name: 'auto_renew', type: 'boolean', default: true })
  autoRenew: boolean;

  /** Latest raw receipt/notification payload retained for audit & re-validation. */
  @Column({ name: 'latest_receipt', type: 'jsonb', nullable: true })
  latestReceipt: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
