/**
 * Compatibility re-export.
 *
 * The canonical `MissionHistory` entity lives with its owning feature module at
 * `src/modules/missions/mission-history.entity.ts`. An earlier draft defined a
 * second `@Entity({ name: 'mission_history' })` class here, which would make
 * TypeORM register two entities for the same table and fail at startup.
 *
 * To keep existing imports (`../../entities/mission-history.entity`) working
 * without duplicating metadata, this module simply re-exports the canonical
 * entity. Prefer importing from `src/modules/missions/mission-history.entity`
 * in new code.
 */
export { MissionHistory } from '../modules/missions/mission-history.entity';
