import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

/**
 * MissionType entity — maps to the `mission_types` table.
 *
 * Catalog of supported mission kinds. `code` is the stable identifier referenced by
 * alarm_missions.mission_type and the public API. `default_config` holds tunable
 * defaults (ranges, counts, thresholds) merged with per-alarm overrides.
 */
export const MISSION_CODES = [
  'math',
  'shake',
  'object_detection',
  'memory',
  'typing',
  'qr',
] as const;

export type MissionCode = (typeof MISSION_CODES)[number];

@Entity({ name: 'mission_types' })
@Unique('uq_mission_types_code', ['code'])
export class MissionType {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** math | shake | object_detection | memory | typing | qr */
  @Column({ type: 'varchar' })
  code: string;

  @Column({ type: 'varchar' })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ name: 'is_premium', type: 'boolean', default: false })
  isPremium: boolean;

  @Column({ name: 'default_config', type: 'jsonb', default: () => "'{}'" })
  defaultConfig: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
