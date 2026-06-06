import { Type } from 'class-transformer';
import {
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

/**
 * Body for POST /sleep/sessions — records (or upserts) a night of sleep for a
 * given calendar date. Times are ISO-8601 timestamps; duration/quality may be
 * supplied by the client or derived server-side from sleep/wake.
 */
export class CreateSleepSessionDto {
  /** Calendar date the session belongs to (the wake-up date). */
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be YYYY-MM-DD' })
  date: string;

  @IsOptional()
  @IsDateString()
  bedtimeAt?: string;

  @IsOptional()
  @IsDateString()
  sleepAt?: string;

  @IsOptional()
  @IsDateString()
  wakeAt?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(1440)
  durationMin?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  qualityScore?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  @Type(() => Number)
  snoozeCount?: number;

  @IsOptional()
  @IsString()
  source?: string;
}
