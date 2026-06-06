import { IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

/**
 * PATCH /users/me body. Every field optional; only profile-safe fields are
 * mutable here (email / role / premium are managed by other flows).
 */
export class UpdateUserDto {
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  displayName?: string;

  // IANA timezone identifier, e.g. "America/New_York" or "UTC".
  @IsOptional()
  @IsString()
  @MaxLength(64)
  @Matches(/^[A-Za-z0-9+_\-\/]+$/, { message: 'Invalid timezone identifier' })
  timezone?: string;

  // BCP-47-ish locale, e.g. "en", "en-US".
  @IsOptional()
  @IsString()
  @MaxLength(10)
  @Matches(/^[a-z]{2}(-[A-Z]{2})?$/, { message: 'Invalid locale' })
  locale?: string;
}
