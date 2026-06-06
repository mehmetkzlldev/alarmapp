import {
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import { MISSION_CODES } from '../../missions/mission-type.entity';

export const DIFFICULTIES = ['easy', 'medium', 'hard'] as const;
export type Difficulty = (typeof DIFFICULTIES)[number];

/**
 * Payload for attaching a mission to an alarm.
 * Used both as a nested element in CreateAlarmDto.missions and standalone via
 * POST /alarms/:id/missions.
 */
export class CreateAlarmMissionDto {
  @IsIn(MISSION_CODES as unknown as string[])
  missionType: string;

  @IsOptional()
  @IsIn(DIFFICULTIES as unknown as string[])
  difficulty: Difficulty = 'medium';

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(50)
  orderIndex = 0;

  /** Free-form per-instance config (e.g. { operandCount, repeatCount }). */
  @IsOptional()
  @IsObject()
  config: Record<string, unknown> = {};
}
