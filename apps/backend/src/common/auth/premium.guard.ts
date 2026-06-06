import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import type { AuthenticatedUser } from './jwt-payload.interface';

/**
 * Route guard that allows the request only for users with an active premium
 * entitlement. Apply AFTER JwtAuthGuard so `request.user` is populated, e.g.:
 *
 *   @UseGuards(JwtAuthGuard, PremiumGuard)
 *   @Get('today') ...
 *
 * `isPremium` is a signed claim placed on the access token by the auth module
 * (derived server-side from the subscription state), so we never trust the
 * client to assert premium directly.
 *
 * For endpoints that are only *partially* gated (e.g. alarms are free up to a
 * limit, then premium), do NOT use this guard at the route level — enforce the
 * conditional rule in the service instead (see AlarmsService.create).
 */
@Injectable()
export class PremiumGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user: AuthenticatedUser | undefined = request.user;

    if (!user) {
      // JwtAuthGuard should have run first; fail closed if not.
      throw new ForbiddenException('Authentication required');
    }

    if (!user.isPremium) {
      throw new ForbiddenException(
        'This feature requires an active premium subscription',
      );
    }

    return true;
  }
}
