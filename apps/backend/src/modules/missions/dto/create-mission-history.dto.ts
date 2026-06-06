import {
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  Min,
} from 'class-validator';
import { MISSION_CODES } from '../mission-type.entity';
import { DIFFICULTIES } from '../../alarms/dto/create-alarm-mission.dto';

export const MISSION_STATUSES = ['success', 'failed', 'skipped'] as const;
export type MissionStatus = (typeof MISSION_STATUSES)[number];

/** Body for POST /missions/history. */
export class CreateMissionHistoryDto {
  @IsOptional()
  @IsUUID()
  alarmId?: string;

  @IsOptional()
  @IsUUID()
  alarmMissionId?: string;

  @IsIn(MISSION_CODES as unknown as string[])
  missionType: string;

  @IsIn(MISSION_STATUSES as unknown as string[])
  status: MissionStatus;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(86_400)
  durationSec?: number;

  @IsOptional()
  @IsIn(DIFFICULTIES as unknown as string[])
  difficulty?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  attemptsCount?: number;

  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}
