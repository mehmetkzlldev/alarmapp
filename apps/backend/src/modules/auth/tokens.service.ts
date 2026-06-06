import { createHash, randomUUID } from 'crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, LessThan, Repository } from 'typeorm';
import { RefreshToken } from '../users/refresh-token.entity';
import { User } from '../users/user.entity';
import type {
  JwtAccessPayload,
  JwtRefreshPayload,
} from '../../common/auth/jwt-payload.interface';

export interface RequestContext {
  userAgent?: string | null;
  ip?: string | null;
}

export interface IssuedTokens {
  accessToken: string;
  refreshToken: string;
}

/**
 * Owns all token cryptography and the refresh_tokens table.
 *
 * Design:
 *  - Access tokens are short-lived stateless JWTs (~15m).
 *  - Refresh tokens are long-lived JWTs (~30d) whose `jti` is the primary key of
 *    a refresh_tokens row. We persist only a SHA-256 hash of the *full* signed
 *    token so a DB leak cannot be replayed.
 *  - Rotation: every successful refresh revokes the presented token and issues a
 *    fresh one (new jti).
 *  - Reuse detection: if a token that is already revoked is presented again, we
 *    treat it as theft and revoke ALL of that user's tokens.
 */
@Injectable()
export class TokensService {
  private readonly accessSecret: string;
  private readonly refreshSecret: string;
  private readonly accessTtl: string;
  private readonly refreshTtl: string;
  private readonly refreshTtlMs: number;

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    @InjectRepository(RefreshToken)
    private readonly refreshRepo: Repository<RefreshToken>,
  ) {
    // Secrets come strictly from configuration / env; never hardcoded.
    this.accessSecret = this.config.getOrThrow<string>('JWT_ACCESS_SECRET');
    this.refreshSecret = this.config.getOrThrow<string>('JWT_REFRESH_SECRET');
    this.accessTtl = this.config.get<string>('JWT_ACCESS_TTL') ?? '15m';
    this.refreshTtl = this.config.get<string>('JWT_REFRESH_TTL') ?? '30d';
    this.refreshTtlMs = this.parseTtlToMs(this.refreshTtl);
  }

  /** Sign a short-lived access token from the canonical user record. */
  private signAccessToken(user: User): Promise<string> {
    const payload: JwtAccessPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      isPremium: user.isPremium,
      tv: 'access',
    };
    return this.jwt.signAsync(payload, {
      secret: this.accessSecret,
      expiresIn: this.accessTtl,
    });
  }

  /** Sign a refresh token bound to a specific refresh_tokens row id (jti). */
  private signRefreshToken(userId: string, jti: string): Promise<string> {
    const payload: JwtRefreshPayload = { sub: userId, jti, tv: 'refresh' };
    return this.jwt.signAsync(payload, {
      secret: this.refreshSecret,
      expiresIn: this.refreshTtl,
    });
  }

  /** SHA-256 hex digest used as the at-rest representation of a refresh token. */
  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  /**
   * Issue a brand-new access+refresh pair and persist the refresh hash.
   * Used on register/login.
   */
  async issueTokenPair(user: User, ctx: RequestContext = {}): Promise<IssuedTokens> {
    // Pre-generate the row UUID so it can double as the JWT `jti`, giving a 1:1
    // token<->row mapping without an extra column. randomUUID() yields a valid
    // v4 UUID that fits the `uuid` primary key.
    const jti = randomUUID();
    const accessToken = await this.signAccessToken(user);
    const refreshToken = await this.signRefreshToken(user.id, jti);

    const entity = this.refreshRepo.create({
      id: jti,
      userId: user.id,
      tokenHash: this.hashToken(refreshToken),
      expiresAt: new Date(Date.now() + this.refreshTtlMs),
      userAgent: ctx.userAgent ?? null,
      ip: ctx.ip ?? null,
    });
    await this.refreshRepo.save(entity);

    return { accessToken, refreshToken };
  }

  /** Verify a refresh JWT's signature/expiry and return its payload. */
  async verifyRefreshToken(token: string): Promise<JwtRefreshPayload> {
    return this.jwt.verifyAsync<JwtRefreshPayload>(token, {
      secret: this.refreshSecret,
    });
  }

  /**
   * Rotate a presented refresh token.
   *
   * Returns the matched (still-valid) row so AuthService can load the user and
   * re-issue. Throws on any anomaly; reuse of a revoked token triggers a full
   * revocation of the user's sessions (theft response).
   */
  async rotate(
    payload: JwtRefreshPayload,
    presentedToken: string,
    user: User,
    ctx: RequestContext = {},
  ): Promise<IssuedTokens> {
    const row = await this.refreshRepo.findOne({ where: { id: payload.jti } });

    // Unknown jti -> token forged or row pruned. Reject.
    if (!row) {
      throw new RefreshTokenError('Refresh token not recognized');
    }

    // Reuse detection: the row exists but was already revoked => the same token
    // was used twice. This is the classic stolen-token signal. Burn everything.
    if (row.revokedAt) {
      await this.revokeAllForUser(payload.sub);
      throw new RefreshTokenError('Refresh token reuse detected');
    }

    // Expired in DB (defensive; JWT verify already checks exp).
    if (row.expiresAt.getTime() <= Date.now()) {
      throw new RefreshTokenError('Refresh token expired');
    }

    // Hash must match the stored hash exactly (binds row<->token).
    if (row.tokenHash !== this.hashToken(presentedToken)) {
      // jti matched but hash didn't: tampering. Revoke this lineage.
      row.revokedAt = new Date();
      await this.refreshRepo.save(row);
      throw new RefreshTokenError('Refresh token mismatch');
    }

    // Happy path: revoke the old row and mint a fresh pair.
    row.revokedAt = new Date();
    await this.refreshRepo.save(row);

    return this.issueTokenPair(user, ctx);
  }

  /** Revoke a single refresh token by its jti (used on logout). Idempotent. */
  async revokeByJti(jti: string): Promise<void> {
    await this.refreshRepo.update(
      { id: jti, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }

  /** Revoke every active refresh token for a user (logout-all / theft). */
  async revokeAllForUser(userId: string): Promise<void> {
    await this.refreshRepo.update(
      { userId, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }

  /** Housekeeping: delete expired/revoked rows. Safe to run on a cron. */
  async pruneExpired(): Promise<void> {
    await this.refreshRepo.delete({ expiresAt: LessThan(new Date()) });
  }

  /** Convert a TTL string like "30d" / "15m" / "900s" to milliseconds. */
  private parseTtlToMs(ttl: string): number {
    const match = /^(\d+)\s*([smhd])$/.exec(ttl.trim());
    if (!match) {
      // Fallback: assume it's already a number of seconds.
      const asNum = Number(ttl);
      return Number.isFinite(asNum) ? asNum * 1000 : 30 * 24 * 60 * 60 * 1000;
    }
    const value = Number(match[1]);
    const unit = match[2];
    const unitMs: Record<string, number> = {
      s: 1000,
      m: 60 * 1000,
      h: 60 * 60 * 1000,
      d: 24 * 60 * 60 * 1000,
    };
    return value * unitMs[unit];
  }
}

/** Thrown for any refresh-token anomaly; mapped to 401 by AuthService. */
export class RefreshTokenError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RefreshTokenError';
  }
}
