import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

/**
 * Body for POST /ai-missions/:id/complete.
 *
 * `imageS3Key` is optional — only object-detection / photo missions submit one.
 * When present it must match the mission-image key namespace.
 */
export class CompleteMissionDto {
  @IsOptional()
  @IsString()
  @MaxLength(512)
  @Matches(/^missions\/[A-Za-z0-9-]+\/\d{4}\/\d{2}\/[A-Za-z0-9-]+\.[a-z]+$/, {
    message: 'imageS3Key is not a valid mission image key',
  })
  imageS3Key?: string;
}

export class CompleteMissionResponseDto {
  status!: 'completed' | 'expired' | 'assigned';
}
