import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { GeminiModule } from '../../integrations/gemini/gemini.module';
import { S3Module } from '../../integrations/s3/s3.module';
import { MissionHistory } from '../missions/mission-history.entity';
import { ObjectDetectionController } from './object-detection.controller';
import { ObjectDetectionService } from './object-detection.service';

/**
 * Object-detection wake-up mission: client uploads a photo, Gemini Vision
 * verifies the requested target object is present.
 *
 * GeminiModule and S3Module are @Global, but we import them explicitly for
 * clarity and to keep this module self-documenting.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([MissionHistory]),
    GeminiModule,
    S3Module,
  ],
  controllers: [ObjectDetectionController],
  providers: [ObjectDetectionService],
  exports: [ObjectDetectionService],
})
export class ObjectDetectionModule {}
