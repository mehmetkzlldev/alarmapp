import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';

/**
 * Canonical `refresh_tokens` table.
 *
 * We store only a *hash* of the opaque refresh token (token_hash). The plaintext
 * token is returned to the client exactly once and never persisted, so a database
 * compromise cannot be used to mint sessions. Rotation + reuse detection lives in
 * AuthService / TokensService.
 */
@Entity({ name: 'refresh_tokens' })
@Index('idx_refresh_tokens_user_id', ['userId'])
@Index('idx_refresh_tokens_token_hash', ['tokenHash'])
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, (user) => user.refreshTokens, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user: User;

  // SHA-256 hex digest of the opaque refresh token (never the raw token).
  @Column({ name: 'token_hash', type: 'varchar' })
  tokenHash: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  // Set when the token is rotated, used, or explicitly logged out.
  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt: Date | null;

  @Column({ name: 'user_agent', type: 'varchar', nullable: true })
  userAgent: string | null;

  @Column({ type: 'varchar', nullable: true })
  ip: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
