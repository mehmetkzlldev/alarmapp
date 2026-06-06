/**
 * Compatibility re-export.
 *
 * The canonical `User` entity lives with its owning feature module at
 * `src/modules/users/user.entity.ts`. Defining a second
 * `@Entity({ name: 'users' })` class here would make TypeORM register two
 * entities for the same table and fail at startup.
 *
 * This module re-exports the canonical entity (and its enums) so any existing
 * `../../entities/user.entity` imports keep working. Prefer importing from
 * `src/modules/users/user.entity` in new code.
 */
export { User } from '../modules/users/user.entity';
export type {
  AuthProvider,
  UserRole,
  UserStatus,
} from '../modules/users/user.entity';
