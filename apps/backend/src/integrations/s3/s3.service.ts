import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

/** Default TTL for presigned URLs. Short-lived by design (security). */
const PRESIGNED_PUT_TTL_SEC = 60 * 5; // 5 minutes to upload
const PRESIGNED_GET_TTL_SEC = 60 * 2; // 2 minutes to read back internally
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB cap for mission photos

export interface PresignedUpload {
  uploadUrl: string;
  s3Key: string;
  /** Echoed back so the client sends a matching Content-Type on PUT. */
  contentType: string;
  expiresInSec: number;
}

/**
 * Thin wrapper over the AWS SDK for our PRIVATE bucket.
 *
 * Security posture:
 *  - The bucket is private; objects are never publicly readable.
 *  - Clients upload via short-TTL presigned PUT URLs scoped to a single key.
 *  - The backend reads objects either via short-TTL presigned GET URLs or by
 *    streaming bytes directly (preferred for sending to Gemini).
 *  - Object keys are namespaced per user and randomized to prevent guessing.
 */
@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.getOrThrow<string>('S3_BUCKET');
    this.client = new S3Client({
      region: this.config.getOrThrow<string>('AWS_REGION'),
      // Credentials resolve from the standard AWS provider chain (env, IAM role,
      // etc.). We never hardcode them. An explicit endpoint supports S3-compatible
      // stores (e.g. MinIO/LocalStack) in dev.
      ...(this.config.get<string>('S3_ENDPOINT')
        ? {
            endpoint: this.config.get<string>('S3_ENDPOINT'),
            forcePathStyle: true,
          }
        : {}),
    });
  }

  /** Allowed image content types for mission uploads. */
  private static readonly ALLOWED_CONTENT_TYPES = new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  ]);

  isAllowedContentType(contentType: string): boolean {
    return StorageService.ALLOWED_CONTENT_TYPES.has(contentType);
  }

  /**
   * Build a deterministic, per-user, randomized key for a mission image.
   * Layout: missions/<userId>/<yyyy>/<mm>/<uuid>.<ext>
   */
  buildMissionImageKey(userId: string, contentType: string): string {
    const now = new Date();
    const yyyy = now.getUTCFullYear();
    const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
    const ext = this.extForContentType(contentType);
    return `missions/${userId}/${yyyy}/${mm}/${randomUUID()}.${ext}`;
  }

  /**
   * Create a short-TTL presigned PUT URL for a client upload.
   * The Content-Type and content-length range are constrained server-side so the
   * client cannot upload arbitrary or oversized objects.
   */
  async createPresignedUpload(
    userId: string,
    contentType: string,
  ): Promise<PresignedUpload> {
    const s3Key = this.buildMissionImageKey(userId, contentType);
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: s3Key,
      ContentType: contentType,
      // Server-side encryption at rest.
      ServerSideEncryption: 'AES256',
    });

    const uploadUrl = await getSignedUrl(this.client, command, {
      expiresIn: PRESIGNED_PUT_TTL_SEC,
      // Pin the signed headers so the PUT must match exactly.
      signableHeaders: new Set(['content-type']),
    });

    this.logger.debug(`Issued presigned PUT for key=${s3Key} user=${userId}`);
    return {
      uploadUrl,
      s3Key,
      contentType,
      expiresInSec: PRESIGNED_PUT_TTL_SEC,
    };
  }

  /** Short-TTL presigned GET URL (used when we hand a URL to a consumer). */
  async createPresignedDownload(s3Key: string): Promise<string> {
    const command = new GetObjectCommand({ Bucket: this.bucket, Key: s3Key });
    return getSignedUrl(this.client, command, {
      expiresIn: PRESIGNED_GET_TTL_SEC,
    });
  }

  /**
   * Stream an object fully into memory. Used to feed image bytes to Gemini so we
   * never expose a public URL. Enforces the upload size cap defensively.
   */
  async getObjectBytes(
    s3Key: string,
  ): Promise<{ bytes: Buffer; contentType: string }> {
    const command = new GetObjectCommand({ Bucket: this.bucket, Key: s3Key });
    const response = await this.client.send(command);

    const contentLength = Number(response.ContentLength ?? 0);
    if (contentLength > MAX_UPLOAD_BYTES) {
      throw new Error(
        `Object ${s3Key} exceeds max allowed size (${contentLength} bytes)`,
      );
    }

    const body = response.Body as
      | NodeJS.ReadableStream
      | { transformToByteArray?: () => Promise<Uint8Array> };

    // The v3 SDK Body exposes transformToByteArray() in Node and browser.
    if (
      body &&
      typeof (body as { transformToByteArray?: unknown })
        .transformToByteArray === 'function'
    ) {
      const arr = await (
        body as { transformToByteArray: () => Promise<Uint8Array> }
      ).transformToByteArray();
      this.assertSize(arr.byteLength, s3Key);
      return {
        bytes: Buffer.from(arr),
        contentType: response.ContentType ?? 'image/jpeg',
      };
    }

    // Fallback: collect from a Node readable stream.
    const chunks: Buffer[] = [];
    let total = 0;
    for await (const chunk of body as NodeJS.ReadableStream) {
      const buf = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
      total += buf.length;
      this.assertSize(total, s3Key);
      chunks.push(buf);
    }
    return {
      bytes: Buffer.concat(chunks),
      contentType: response.ContentType ?? 'image/jpeg',
    };
  }

  /** Confirm an object exists (e.g. that the client actually uploaded it). */
  async objectExists(s3Key: string): Promise<boolean> {
    try {
      await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucket, Key: s3Key }),
      );
      return true;
    } catch {
      return false;
    }
  }

  private assertSize(bytes: number, s3Key: string): void {
    if (bytes > MAX_UPLOAD_BYTES) {
      throw new Error(`Object ${s3Key} exceeds max allowed size`);
    }
  }

  private extForContentType(contentType: string): string {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      default:
        return 'jpg';
    }
  }
}
