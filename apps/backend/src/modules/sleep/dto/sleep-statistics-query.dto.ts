import { IsIn, IsOptional } from 'class-validator';

/** Query for GET /sleep/statistics?range=week|month. Defaults to week. */
export class SleepStatisticsQueryDto {
  @IsOptional()
  @IsIn(['week', 'month'])
  range?: 'week' | 'month' = 'week';
}
