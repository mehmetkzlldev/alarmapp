/**
 * Compatibility re-export.
 *
 * The canonical `@CurrentUser()` param decorator lives at
 * `src/common/auth/current-user.decorator.ts`. This shim supports modules that
 * import it from `common/decorators/...`.
 */
export { CurrentUser } from '../auth/current-user.decorator';
