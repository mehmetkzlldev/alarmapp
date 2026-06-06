/**
 * `AuthUser` is an alias of the canonical `AuthenticatedUser` shape attached to
 * `request.user` by the JWT strategy. Some feature modules (sleep,
 * subscriptions) import the type under this name/path; keeping it a re-export
 * guarantees the two names never drift apart.
 */
export type { AuthenticatedUser as AuthUser } from '../auth/jwt-payload.interface';
