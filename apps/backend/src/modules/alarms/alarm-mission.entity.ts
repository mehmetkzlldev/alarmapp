import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Alarm } from './alarm.entity';
import { MissionType } from '../missions/mission-type.entity';

/**
 * AlarmMission entity — maps to the `alarm_missions` table.
 *
 * A join/config row that attaches a mission (by its `mission_type` code) to an alarm
 * with an explicit ordering and per-instance difficulty/config overrides.
 *
 * UNIQUE(alarm_id, order_index) guarantees a stable, gap-free-ish ordering of the
 * missions a user must complete to dismiss a given alarm.
 */
@Entity({ name: 'alarm_missions' })
@Unique('uq_alarm_missions_alarm_order', ['alarmId', 'orderIndex'])
@Index('idx_alarm_missions_alarm_id', ['alarmId'])
export class AlarmMission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'alarm_id', type: 'uuid' })
  alarmId: string;

  @ManyToOne(() => Alarm, (alarm) => alarm.missions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'alarm_id' })
  alarm: Alarm;

  /**
   * FK to mission_types(code). Stored as the varchar code (math|shake|object_detection|...)
   * rather than the mission_types PK so the client contract can speak in stable codes.
   */
  @Column({ name: 'mission_type', type: 'varchar' })
  missionType: string;

  @ManyToOne(() => MissionType, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'mission_type', referencedColumnName: 'code' })
  missionTypeRef?: MissionType;

  @Column({ name: 'order_index', type: 'smallint', default: 0 })
  orderIndex: number;

  /** easy | medium | hard */
  @Column({ type: 'varchar', default: 'medium' })
  difficulty: string;

  /** Per-instance overrides merged on top of mission_types.default_config at runtime. */
  @Column({ type: 'jsonb', default: () => "'{}'" })
  config: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
