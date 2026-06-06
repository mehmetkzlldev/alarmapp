import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../constants';
import type { AuthenticatedUser } from '../auth/jwt-payload.interface';

/**
 * Role-based authorization guard.
 *
 * Reads roles declared via `@Roles(...)` and compares against the authenticated
 * user's role. Routes without the decorator are unrestricted (assuming they
 * already passed `JwtAuthGuard`).
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // Roles are declared as plain strings (the `UserRole` enum is string-valued)
    // so this guard stays decoupled from the entity layer's enum definition.
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: AuthenticatedUser | undefined = request.user;

    if (!user || !requiredRoles.includes(String(user.role))) {
      throw new ForbiddenException('Insufficient role permissions');
    }
    return true;
  }
}
