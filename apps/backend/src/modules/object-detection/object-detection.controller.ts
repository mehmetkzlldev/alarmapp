import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';

import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { ObjectDetectionService } from './object-detection.service';
import { UploadUrlDto, UploadUrlResponseDto } from './dto/upload-url.dto';
import {
  VerifyDetectionDto,
  VerifyDetectionResponseDto,
} from './dto/verify-detection.dto';
import { VerifyImageDto } from './dto/verify-image.dto';

/**
 * Routes:
 *   POST /api/v1/object-detection/upload-url -> presigned S3 PUT
 *   POST /api/v1/object-detection/verify     -> Gemini Vision verification
 *
 * All routes require a valid access token.
 */
@Controller('object-detection')
@UseGuards(JwtAuthGuard)
export class ObjectDetectionController {
  constructor(private readonly service: ObjectDetectionService) {}

  @Post('upload-url')
  @HttpCode(HttpStatus.OK)
  async createUploadUrl(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UploadUrlDto,
  ): Promise<UploadUrlResponseDto> {
    const { uploadUrl, s3Key } = await this.service.createUploadUrl(
      user.id,
      dto.contentType,
    );
    return { uploadUrl, s3Key };
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  async verify(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: VerifyDetectionDto,
  ): Promise<VerifyDetectionResponseDto> {
    return this.service.verify(user.id, dto.s3Key, dto.targetObject);
  }

  /**
   * Direct (no-S3) verification: the client sends the photo inline as base64.
   * POST /api/v1/object-detection/verify-image
   */
  @Post('verify-image')
  @HttpCode(HttpStatus.OK)
  async verifyImage(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: VerifyImageDto,
  ): Promise<VerifyDetectionResponseDto> {
    return this.service.verifyDirect(user.id, dto.imageBase64, dto.targetObject);
  }
}
