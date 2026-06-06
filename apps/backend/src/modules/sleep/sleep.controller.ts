import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { PremiumGuard } from '../../common/auth/premium.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { Premium } from '../../common/decorators/premium.decorator';
import { CreateSleepSessionDto } from './dto/create-sleep-session.dto';
import { SleepStatisticsQueryDto } from './dto/sleep-statistics-query.dto';
import { SleepStatistic } from './sleep-statistic.entity';
import {
  SleepService,
  SleepStatisticsResult,
} from './sleep.service';

/**
 * Base path: /api/v1/sleep.
 *
 * GET /sleep/statistics is premium-gated. We annotate with @Premium() (consumed
 * by the metadata-driven global PremiumGuard) AND apply @UseGuards(PremiumGuard)
 * so the gate holds regardless of how the guard pipeline is wired. Recording
 * sessions stays open to all authenticated users so free users still accumulate
 * data they can unlock later by upgrading.
 */
@Controller('sleep')
@UseGuards(JwtAuthGuard)
export class SleepController {
  constructor(private readonly sleep: SleepService) {}

  /** GET /sleep/statistics?range=week|month — premium only. */
  @Get('statistics')
  @Premium()
  @UseGuards(PremiumGuard)
  statistics(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SleepStatisticsQueryDto,
  ): Promise<SleepStatisticsResult> {
    return this.sleep.getStatistics(user.id, query.range ?? 'week');
  }

  /** POST /sleep/sessions — upsert a night's sleep stats. */
  @Post('sessions')
  recordSession(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSleepSessionDto,
  ): Promise<SleepStatistic> {
    return this.sleep.recordSession(user.id, dto);
  }
}
