import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import type {
  AuthenticatedUser,
  JwtAccessPayload,
} from '../../common/auth/jwt-payload.interface';

/**
 * Passport 'jwt' strategy validating the **access** token from the
 * Authorization: Bearer header. Its return value becomes request.user.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
    });
  }

  /**
   * Called by passport after the signature/expiry check passes. We trust the
   * stateless claims for the request lifetime (access tokens are short-lived);
   * no DB hit is needed on the hot path.
   */
  async validate(payload: JwtAccessPayload): Promise<AuthenticatedUser> {
    // Reject refresh tokens presented as access tokens.
    if (payload.tv !== 'access') {
      throw new UnauthorizedException('Invalid access token');
    }
    return {
      id: payload.sub,
      email: payload.email,
      role: payload.role,
      isPremium: payload.isPremium,
    };
  }
}
