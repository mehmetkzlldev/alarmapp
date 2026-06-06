import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SleepStatistic } from './sleep-statistic.entity';
import { SleepController } from './sleep.controller';
import { SleepService } from './sleep.service';

@Module({
  imports: [TypeOrmModule.forFeature([SleepStatistic])],
  controllers: [SleepController],
  providers: [SleepService],
  exports: [SleepService],
})
export class SleepModule {}
