import { ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../constants';

/**
 * Default guard for protected routes. Delegates to the 'jwt' passport strategy
 * (see auth/jwt.strategy.ts) which validates the Bearer access token and
 * populates request.user with an AuthenticatedUser.
 *
 * Honors the @Public() decorator: a route (or controller) marked @Public()
 * bypasses authentication. This lets the same guard sit on a controller whose
 * individual webhook routes must stay open (e.g. store IAP callbacks).
 *
 * Lives in `common` so every feature module (alarms, devices, ...) can reuse it.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }
    return super.canActivate(context);
  }
}
