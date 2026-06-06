import {
  createParamDecorator,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import type { AuthenticatedUser } from './jwt-payload.interface';

/**
 * Param decorator that extracts the authenticated user (populated by
 * JwtStrategy.validate) from the request.
 *
 * Usage:
 *   getMe(@CurrentUser() user: AuthenticatedUser) { ... }
 *   getMyId(@CurrentUser('id') userId: string) { ... }
 */
export const CurrentUser = createParamDecorator(
  (
    data: keyof AuthenticatedUser | undefined,
    ctx: ExecutionContext,
  ): AuthenticatedUser | AuthenticatedUser[keyof AuthenticatedUser] => {
    const request = ctx.switchToHttp().getRequest();
    const user: AuthenticatedUser | undefined = request.user;

    if (!user) {
      // Should never happen when JwtAuthGuard is applied, but fail closed.
      throw new UnauthorizedException('Authentication required');
    }

    return data ? user[data] : user;
  },
);
