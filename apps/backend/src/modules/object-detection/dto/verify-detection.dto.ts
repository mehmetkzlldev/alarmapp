import { IsIn, IsString, Matches, MaxLength } from 'class-validator';

import { SUPPORTED_OBJECTS } from '../object-detection.constants';

/**
 * Body for POST /object-detection/verify.
 *
 * `targetObject` is validated against the closed SUPPORTED_OBJECTS list so we
 * never feed an arbitrary attacker-controlled target into the model.
 * `s3Key` is constrained to the mission key namespace to prevent path-traversal
 * or reading arbitrary objects in the bucket.
 */
export class VerifyDetectionDto {
  @IsString()
  @MaxLength(512)
  // Keys are issued by us as missions/<userId>/<yyyy>/<mm>/<uuid>.<ext>.
  // Restricting the shape blocks attempts to point at unrelated objects.
  @Matches(/^missions\/[A-Za-z0-9-]+\/\d{4}\/\d{2}\/[A-Za-z0-9-]+\.[a-z]+$/, {
    message: 's3Key is not a valid mission image key',
  })
  s3Key!: string;

  @IsString()
  @IsIn(SUPPORTED_OBJECTS as unknown as string[], {
    message: `targetObject must be one of: ${SUPPORTED_OBJECTS.join(', ')}`,
  })
  targetObject!: string;
}

/** Shape returned to the client (mirrors the API contract). */
export class VerifyDetectionResponseDto {
  isMatch!: boolean;
  confidence!: number; // 0..1
  detectedObjects!: string[];
  reasoning!: string;
}
