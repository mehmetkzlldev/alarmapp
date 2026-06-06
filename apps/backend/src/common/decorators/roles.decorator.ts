import { SetMetadata } from '@nestjs/common';
import { ROLES_KEY } from '../constants';
import type { UserRole } from '../auth/jwt-payload.interface';

/**
 * Restricts a route to the given roles. Enforced by `RolesGuard`.
 * Example: `@Roles('admin')`.
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
