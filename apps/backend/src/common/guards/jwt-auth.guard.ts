/**
 * Compatibility re-export.
 *
 * The canonical `JwtAuthGuard` lives at `src/common/auth/jwt-auth.guard.ts`.
 * Some feature modules import it from `common/guards/...`; this shim points
 * those imports at the single canonical implementation so there is exactly one
 * guard class in the DI container.
 */
export { JwtAuthGuard } from '../auth/jwt-auth.guard';
