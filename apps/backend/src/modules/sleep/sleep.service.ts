import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { CreateSleepSessionDto } from './dto/create-sleep-session.dto';
import { SleepStatistic } from './sleep-statistic.entity';

/** A single day's point in the statistics response. */
export interface SleepPoint {
  date: string; // YYYY-MM-DD
  durationMin: number | null;
  qualityScore: number | null;
  snoozeCount: number;
  missionSuccessRate: number | null; // 0..100
}

/** Shape returned by GET /sleep/statistics. */
export interface SleepStatisticsResult {
  points: SleepPoint[];
  avgDurationMin: number | null;
  /** 0..100; higher = more consistent bedtime/duration. */
  consistencyScore: number | null;
  /** 0..100 average mission success across the range. */
  missionSuccessRate: number | null;
}

@Injectable()
export class SleepService {
  constructor(
    @InjectRepository(SleepStatistic)
    private readonly repo: Repository<SleepStatistic>,
  ) {}

  /**
   * POST /sleep/sessions — upsert a night's stats for (user, date).
   * Derives duration from sleep/wake when not explicitly provided, and computes
   * the mission success rate for that night from mission_history.
   */
  async recordSession(
    userId: string,
    dto: CreateSleepSessionDto,
  ): Promise<SleepStatistic> {
    let row = await this.repo.findOne({
      where: { userId, date: dto.date },
    });
    if (!row) {
      row = this.repo.create({ userId, date: dto.date });
    }

    row.bedtimeAt = dto.bedtimeAt ? new Date(dto.bedtimeAt) : row.bedtimeAt;
    row.sleepAt = dto.sleepAt ? new Date(dto.sleepAt) : row.sleepAt;
    row.wakeAt = dto.wakeAt ? new Date(dto.wakeAt) : row.wakeAt;

    // Prefer an explicit duration; otherwise derive from sleep -> wake.
    if (typeof dto.durationMin === 'number') {
      row.durationMin = dto.durationMin;
    } else if (row.sleepAt && row.wakeAt) {
      row.durationMin = Math.max(
        0,
        Math.round((row.wakeAt.getTime() - row.sleepAt.getTime()) / 60000),
      );
    }

    if (typeof dto.qualityScore === 'number') {
      row.qualityScore = dto.qualityScore;
    }
    if (typeof dto.snoozeCount === 'number') {
      row.snoozeCount = dto.snoozeCount;
    }
    if (dto.source) {
      row.source = dto.source;
    }

    // Compute and store that night's mission success rate.
    const rate = await this.missionSuccessRateForDate(userId, dto.date);
    row.missionSuccessRate = rate === null ? row.missionSuccessRate : rate.toFixed(2);

    return this.repo.save(row);
  }

  /**
   * GET /sleep/statistics?range=week|month
   * Aggregates the user's recent sleep into points + summary metrics.
   */
  async getStatistics(
    userId: string,
    range: 'week' | 'month',
  ): Promise<SleepStatisticsResult> {
    const days = range === 'month' ? 30 : 7;
    const { startStr, endStr } = this.dateRange(days);

    const rows = await this.repo.find({
      where: { userId, date: Between(startStr, endStr) },
      order: { date: 'ASC' },
    });

    const points: SleepPoint[] = rows.map((r) => ({
      date: r.date,
      durationMin: r.durationMin,
      qualityScore: r.qualityScore,
      snoozeCount: r.snoozeCount,
      missionSuccessRate:
        r.missionSuccessRate === null ? null : Number(r.missionSuccessRate),
    }));

    const durations = points
      .map((p) => p.durationMin)
      .filter((d): d is number => typeof d === 'number');

    const avgDurationMin =
      durations.length > 0
        ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length)
        : null;

    const rates = points
      .map((p) => p.missionSuccessRate)
      .filter((r): r is number => typeof r === 'number');
    const missionSuccessRate =
      rates.length > 0
        ? Number(
            (rates.reduce((a, b) => a + b, 0) / rates.length).toFixed(2),
          )
        : null;

    return {
      points,
      avgDurationMin,
      consistencyScore: this.consistencyScore(durations),
      missionSuccessRate,
    };
  }

  /**
   * Consistency score (0..100) derived from the coefficient of variation of
   * sleep duration: lower variability => higher consistency. Returns null when
   * there is insufficient data (<2 nights).
   */
  private consistencyScore(durations: number[]): number | null {
    if (durations.length < 2) return null;
    const mean = durations.reduce((a, b) => a + b, 0) / durations.length;
    if (mean === 0) return null;
    const variance =
      durations.reduce((a, b) => a + (b - mean) ** 2, 0) / durations.length;
    const std = Math.sqrt(variance);
    const cv = std / mean; // coefficient of variation
    // Map cv=0 -> 100, cv>=0.5 -> 0 (clamped). 50% variation is "very inconsistent".
    const score = Math.max(0, Math.min(100, 100 * (1 - cv / 0.5)));
    return Math.round(score);
  }

  /**
   * Mission success rate (0..100) for a given user+date computed from
   * mission_history. Uses a raw, parameterized query against the table managed
   * by the missions module to avoid a hard entity import cycle.
   */
  private async missionSuccessRateForDate(
    userId: string,
    date: string,
  ): Promise<number | null> {
    const rows = await this.repo.manager.query<
      { total: string; success: string }[]
    >(
      `SELECT COUNT(*)::text AS total,
              COUNT(*) FILTER (WHERE status = 'success')::text AS success
         FROM mission_history
        WHERE user_id = $1
          AND created_at::date = $2::date`,
      [userId, date],
    );
    const total = Number(rows?.[0]?.total ?? 0);
    if (total === 0) return null;
    const success = Number(rows?.[0]?.success ?? 0);
    return Number(((success / total) * 100).toFixed(2));
  }

  /** Inclusive [start,end] date strings spanning `days` ending today (UTC). */
  private dateRange(days: number): { startStr: string; endStr: string } {
    const end = new Date();
    const start = new Date(end);
    start.setUTCDate(start.getUTCDate() - (days - 1));
    return {
      startStr: this.toDateStr(start),
      endStr: this.toDateStr(end),
    };
  }

  private toDateStr(d: Date): string {
    return d.toISOString().slice(0, 10);
  }
}
