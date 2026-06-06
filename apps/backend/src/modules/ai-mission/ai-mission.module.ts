import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { GeminiModule } from '../../integrations/gemini/gemini.module';
import { CacheModule } from '../../common/cache/cache.module';
import { User } from '../users/user.entity';
import { DailyAiMission } from './ai-mission.entity';
import { AiMissionController } from './ai-mission.controller';
import { AiMissionService } from './ai-mission.service';
import { AiMissionScheduler } from './ai-mission.scheduler';

/**
 * Daily AI wake-up mission feature.
 *
 * Note: ScheduleModule.forRoot() must be imported once at the app root for the
 * @Cron in AiMissionScheduler to fire. CacheModule and GeminiModule are @Global
 * but imported here for clarity / explicit dependency documentation.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([DailyAiMission, User]),
    GeminiModule,
    CacheModule,
  ],
  controllers: [AiMissionController],
  providers: [AiMissionService, AiMissionScheduler],
  exports: [AiMissionService],
})
export class AiMissionModule {}
