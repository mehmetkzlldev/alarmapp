import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MissionType } from './mission-type.entity';
import { MissionHistory } from './mission-history.entity';
import { MissionsController } from './missions.controller';
import { MissionsService } from './missions.service';

/**
 * Missions feature module.
 *
 * Uses the global CacheModule's REDIS_CLIENT (provided @Global) to cache math
 * answers, so it is not imported here. Exports MissionsService for reuse by the
 * AI-missions module (which records history/outcomes).
 */
@Module({
  imports: [TypeOrmModule.forFeature([MissionType, MissionHistory])],
  controllers: [MissionsController],
  providers: [MissionsService],
  exports: [MissionsService, TypeOrmModule],
})
export class MissionsModule {}
