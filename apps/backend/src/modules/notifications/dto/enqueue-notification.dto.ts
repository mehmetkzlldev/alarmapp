import {
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/**
 * Internal DTO used by other modules (e.g. the alarm scheduler) to enqueue a
 * push. Not exposed as a public HTTP endpoint — validated for defense in depth.
 */
export class EnqueueNotificationDto {
  @IsString()
  userId: string;

  @IsString()
  @MaxLength(64)
  type: string;

  @IsString()
  @MaxLength(200)
  title: string;

  @IsString()
  @MaxLength(2000)
  body: string;

  @IsOptional()
  @IsObject()
  data?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  channel?: string;
}
