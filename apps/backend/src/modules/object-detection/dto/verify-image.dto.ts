import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';

import { SUPPORTED_OBJECTS } from '../object-detection.constants';

/**
 * Body for POST /object-detection/verify-image.
 *
 * The client sends the captured photo inline as base64 (optionally with a
 * `data:` URL prefix) instead of uploading to S3 first. `targetObject` is
 * validated against the closed SUPPORTED_OBJECTS allow-list so we never feed an
 * arbitrary attacker-controlled target into the model.
 */
export class VerifyImageDto {
  @IsString()
  @MinLength(100)
  // ~11MB binary once decoded; the express body limit (15mb) is the outer cap.
  @MaxLength(15_000_000)
  imageBase64!: string;

  @IsString()
  @IsIn(SUPPORTED_OBJECTS as unknown as string[], {
    message: `targetObject must be one of: ${SUPPORTED_OBJECTS.join(', ')}`,
  })
  targetObject!: string;
}
