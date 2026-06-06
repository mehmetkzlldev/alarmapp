import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { RefreshToken } from './refresh-token.entity';

/**
 * Authentication provider used to create the account.
 * Mirrors users.auth_provider CHECK constraint.
 */
export type AuthProvider = 'email' | 'google' | 'apple';

/** Application role. Mirrors users.role CHECK constraint. */
export type UserRole = 'user' | 'admin';

/** Lifecycle status. Mirrors users.status CHECK constraint. */
export type UserStatus = 'active' | 'suspended' | 'deleted';

/**
 * Canonical `users` table.
 *
 * NOTE: the `email` column is declared with the Postgres `citext` type so that
 * uniqueness / lookups are case-insensitive at the database level. The actual
 * `citext` extension is enabled by the migration that owns the schema; here we
 * only describe the column so TypeORM maps it correctly.
 */
@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // case-insensitive unique email (citext)
  @Index('uq_users_email', { unique: true })
  @Column({ type: 'citext', unique: true })
  email: string;

  // Nullable: social-login accounts (google/apple) have no local password.
  // Never selected by default so it cannot leak through generic finds.
  @Column({ name: 'password_hash', type: 'varchar', nullable: true, select: false })
  passwordHash: string | null;

  @Index('uq_users_firebase_uid', { unique: true })
  @Column({ name: 'firebase_uid', type: 'varchar', nullable: true, unique: true })
  firebaseUid: string | null;

  @Column({ name: 'auth_provider', type: 'varchar', default: 'email' })
  authProvider: AuthProvider;

  @Column({ name: 'display_name', type: 'varchar', nullable: true })
  displayName: string | null;

  @Column({ name: 'avatar_url', type: 'varchar', nullable: true })
  avatarUrl: string | null;

  @Column({ name: 'email_verified', type: 'boolean', default: false })
  emailVerified: boolean;

  @Column({ type: 'varchar', default: 'user' })
  role: UserRole;

  @Column({ type: 'varchar', default: 'UTC' })
  timezone: string;

  @Column({ type: 'varchar', default: 'en' })
  locale: string;

  @Column({ name: 'is_premium', type: 'boolean', default: false })
  isPremium: boolean;

  @Column({ name: 'premium_until', type: 'timestamptz', nullable: true })
  premiumUntil: Date | null;

  @Column({ type: 'varchar', default: 'active' })
  status: UserStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;

  // ----- relations -----

  @OneToMany(() => RefreshToken, (token) => token.user)
  refreshTokens: RefreshToken[];
}
