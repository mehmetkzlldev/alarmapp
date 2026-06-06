import { IsIn, IsString } from 'class-validator';

/** Allowed image MIME types for a mission photo upload. */
const ALLOWED_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
] as const;

/**
 * Body for POST /object-detection/upload-url.
 * The client declares the content type up front so we can pin it into the
 * presigned PUT signature.
 */
export class UploadUrlDto {
  @IsString()
  @IsIn(ALLOWED_CONTENT_TYPES as unknown as string[], {
    message: `contentType must be one of: ${ALLOWED_CONTENT_TYPES.join(', ')}`,
  })
  contentType!: string;
}

export class UploadUrlResponseDto {
  uploadUrl!: string;
  s3Key!: string;
}
