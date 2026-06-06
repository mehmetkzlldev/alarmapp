import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Alarm } from './alarm.entity';
import { AlarmMission } from './alarm-mission.entity';
import { AlarmsController } from './alarms.controller';
import { AlarmsService } from './alarms.service';

/**
 * Alarms feature module.
 *
 * Depends on the global CacheModule (CacheService) and AppConfigModule
 * (AppConfigService) — both registered @Global, so they are not imported here.
 * Exports AlarmsService so other modules (e.g. scheduling/notifications) can
 * read/recompute triggers.
 */
@Module({
  imports: [TypeOrmModule.forFeature([Alarm, AlarmMission])],
  controllers: [AlarmsController],
  providers: [AlarmsService],
  exports: [AlarmsService, TypeOrmModule],
})
export class AlarmsModule {}
