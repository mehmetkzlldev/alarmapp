import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { CreateAlarmMissionDto } from './create-alarm-mission.dto';

/**
 * Matches "HH:mm" or "HH:mm:ss" 24-hour wall-clock time.
 * The DB column is `time`; we normalize to HH:mm:ss in the service.
 */
const TIME_REGEX = /^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/;

/**
 * IANA-ish timezone string. We keep this permissive (length + charset) and validate
 * resolvability with luxon/Intl inside the service, returning a 400 if unknown.
 */
const TZ_REGEX = /^[A-Za-z0-9_+\-/]{1,64}$/;

export class CreateAlarmDto {
  @IsOptional()
  @IsString()
  @Length(1, 100)
  label?: string = 'Alarm';

  @IsString()
  @Matches(TIME_REGEX, { message: 'time must be HH:mm or HH:mm:ss (24h)' })
  time: string;

  @IsOptional()
  @IsString()
  @Matches(TZ_REGEX, { message: 'timezone must be a valid IANA timezone' })
  timezone?: string = 'UTC';

  /** Weekday indices 0..6 (0=Sun). Empty => one-shot. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(7)
  @IsInt({ each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  repeatDays?: number[] = [];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean = true;

  @IsOptional()
  @IsString()
  @Length(1, 64)
  sound?: string = 'default';

  @IsOptional()
  @IsBoolean()
  vibration?: boolean = true;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  volume?: number = 80;

  @IsOptional()
  @IsBoolean()
  gradualVolume?: boolean = false;

  @IsOptional()
  @IsBoolean()
  snoozeEnabled?: boolean = true;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(60)
  snoozeIntervalMin?: number = 5;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(20)
  snoozeLimit?: number = 3;

  /** Missions a user must clear to dismiss the alarm, in order. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => CreateAlarmMissionDto)
  missions?: CreateAlarmMissionDto[] = [];
}
