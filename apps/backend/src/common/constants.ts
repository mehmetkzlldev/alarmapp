/** Reflector metadata keys shared across decorators and guards. */
export const IS_PUBLIC_KEY = 'isPublic';
export const ROLES_KEY = 'roles';
export const REQUIRES_PREMIUM_KEY = 'requiresPremium';

/**
 * The canonical `UserRole` type is defined in
 * `src/common/auth/jwt-payload.interface.ts` (and mirrors `users.role`). It is
 * intentionally NOT re-exported here to avoid an ambiguous double-export from
 * the `common` barrel — import it from `common/auth` where needed.
 */

/** Convenient string constants for the known roles. */
export const ROLE_USER = 'user';
export const ROLE_ADMIN = 'admin';
