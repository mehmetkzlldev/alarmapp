import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { UsersService, UserProfile } from '../users/users.service';
import { User } from '../users/user.entity';
import {
  IssuedTokens,
  RefreshTokenError,
  RequestContext,
  TokensService,
} from './tokens.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import type { JwtRefreshPayload } from '../../common/auth/jwt-payload.interface';

export interface AuthResult {
  user: UserProfile;
  accessToken: string;
  refreshToken: string;
}

/**
 * argon2id parameters. argon2id is the recommended general-purpose variant
 * (resistant to both GPU and side-channel attacks). These costs are a sane
 * production default (~ tens of ms on modern hardware).
 */
const ARGON2_OPTIONS: argon2.Options = {
  type: argon2.argon2id,
  memoryCost: 19_456, // 19 MiB
  timeCost: 2,
  parallelism: 1,
};

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly tokens: TokensService,
  ) {}

  /** Register a new email/password account and return tokens. */
  async register(dto: RegisterDto, ctx: RequestContext = {}): Promise<AuthResult> {
    const passwordHash = await argon2.hash(dto.password, ARGON2_OPTIONS);

    // createEmailUser maps the unique-email violation to a 409 Conflict.
    const user = await this.users.createEmailUser({
      email: dto.email,
      passwordHash,
      displayName: dto.displayName,
    });

    return this.buildAuthResult(user, ctx);
  }

  /** Validate credentials and issue a fresh token pair. */
  async login(dto: LoginDto, ctx: RequestContext = {}): Promise<AuthResult> {
    const user = await this.users.findByEmailWithPassword(dto.email);

    // Run a verify even when the user is missing to keep timing roughly constant
    // and avoid leaking which emails exist (uses a throwaway hash).
    const hash = user?.passwordHash ?? DUMMY_ARGON2_HASH;
    const passwordOk = await this.safeVerify(hash, dto.password);

    if (!user || !user.passwordHash || !passwordOk) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.status !== 'active') {
      throw new UnauthorizedException('Account is not active');
    }

    return this.buildAuthResult(user, ctx);
  }

  /**
   * Rotate a refresh token: verify signature, load the user, then delegate to
   * TokensService which enforces hash match + reuse detection.
   */
  async refresh(
    refreshToken: string,
    ctx: RequestContext = {},
  ): Promise<IssuedTokens> {
    let payload: JwtRefreshPayload;
    try {
      payload = await this.tokens.verifyRefreshToken(refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (payload.tv !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.users.findById(payload.sub);
    if (!user || user.status !== 'active') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    try {
      return await this.tokens.rotate(payload, refreshToken, user, ctx);
    } catch (err) {
      if (err instanceof RefreshTokenError) {
        throw new UnauthorizedException(err.message);
      }
      throw err;
    }
  }

  /**
   * Logout: revoke the presented refresh token. Best-effort and idempotent — an
   * invalid/expired token still results in a clean 204 so clients can always
   * "log out".
   */
  async logout(refreshToken: string): Promise<void> {
    try {
      const payload = await this.tokens.verifyRefreshToken(refreshToken);
      if (payload.tv === 'refresh' && payload.jti) {
        await this.tokens.revokeByJti(payload.jti);
      }
    } catch {
      // Already invalid/expired => nothing to revoke. Treat as success.
    }
  }

  // ----- helpers -----

  private async buildAuthResult(
    user: User,
    ctx: RequestContext,
  ): Promise<AuthResult> {
    const tokens = await this.tokens.issueTokenPair(user, ctx);
    return {
      user: this.users.toProfile(user),
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  /** argon2.verify that never throws (malformed hash => false). */
  private async safeVerify(hash: string, password: string): Promise<boolean> {
    try {
      return await argon2.verify(hash, password);
    } catch {
      return false;
    }
  }
}

/**
 * A precomputed argon2id hash of a random string, used purely to equalize timing
 * for unknown-email logins. It never matches any real password.
 */
const DUMMY_ARGON2_HASH =
  '$argon2id$v=19$m=19456,t=2,p=1$c29tZXNhbHRzb21lc2FsdA$Hh3i0qQpQh0m2x2H0t8m5n9pQh0m2x2H0t8m5n9pQh0';
