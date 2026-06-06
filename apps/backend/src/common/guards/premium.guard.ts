/**
 * Compatibility re-export.
 *
 * The canonical `PremiumGuard` lives at `src/common/auth/premium.guard.ts`.
 * This shim lets modules that import it from `common/guards/...` resolve to the
 * same implementation (no duplicate class).
 */
export { PremiumGuard } from '../auth/premium.guard';
