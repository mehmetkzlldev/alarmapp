/**
 * Application role. Kept as a local string-literal union so this common/auth
 * primitive stays decoupled from feature modules (mirrors users.role values).
 */
export type UserRole = 'user' | 'admin';

/**
 * Shape of the signed access-token claims.
 *
 * `sub` is the user id, `tv` ("token type") distinguishes access vs refresh so a
 * refresh token can never be replayed as an access token.
 */
export interface JwtAccessPayload {
  sub: string;
  email: string;
  role: UserRole;
  isPremium: boolean;
  tv: 'access';
  iat?: number;
  exp?: number;
}

/** Refresh-token claims. Carries the refresh-token row id (`jti`) for rotation. */
export interface JwtRefreshPayload {
  sub: string;
  jti: string;
  tv: 'refresh';
  iat?: number;
  exp?: number;
}

/**
 * The object attached to `request.user` by JwtStrategy.validate(). This is what
 * the @CurrentUser() decorator returns to controllers.
 */
export interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
  isPremium: boolean;
}
