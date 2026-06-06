import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';

import { User } from '../users/user.entity';
import { AiMissionService } from './ai-mission.service';
import {
  isLocalMidnightHour,
  localDateString,
} from './ai-mission.util';

/**
 * Generates daily AI missions at each user's *local* midnight.
 *
 * Approach: run hourly. On each tick, select premium, active users whose
 * timezone is currently in the 00:00–00:59 local window, and ensure a mission
 * row exists for their local date. Generation is idempotent (UNIQUE(user_id,
 * date) + getOrCreateForDate), so overlapping ticks or a missed run self-heal:
 * the lazy GET fallback also covers any user the scheduler skipped.
 *
 * For very large user bases this should move to a BullMQ fan-out (one job per
 * timezone bucket); the hourly cron is the pragmatic default and is safe because
 * the work is idempotent and batched.
 */
@Injectable()
export class AiMissionScheduler {
  private readonly logger = new Logger(AiMissionScheduler.name);
  private static readonly BATCH_SIZE = 200;

  constructor(
    private readonly aiMissionService: AiMissionService,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  /** Runs at minute 5 of every hour to avoid the top-of-hour thundering herd. */
  @Cron('0 5 * * * *', { name: 'generate-daily-ai-missions' })
  async generateForMidnightUsers(): Promise<void> {
    const startedAt = Date.now();
    let processed = 0;
    let generated = 0;
    let offset = 0;

    // Page through eligible users so we never load the whole table into memory.
    for (;;) {
      const users = await this.fetchEligibleUsers(offset);
      if (users.length === 0) break;

      for (const user of users) {
        const tz = user.timezone || 'UTC';
        // Only generate for users for whom it is currently just past midnight.
        if (!isLocalMidnightHour(tz)) continue;

        processed += 1;
        try {
          const date = localDateString(tz);
          const before = await this.aiMissionService
            .getOrCreateForDate(user.id, tz, date)
            .then(() => true)
            .catch((err) => {
              this.logger.error(
                `Failed generating mission for user=${user.id}: ${
                  (err as Error).message
                }`,
              );
              return false;
            });
          if (before) generated += 1;
        } catch (err) {
          this.logger.error(
            `Unexpected error for user=${user.id}: ${(err as Error).message}`,
          );
        }
      }

      offset += users.length;
      if (users.length < AiMissionScheduler.BATCH_SIZE) break;
    }

    this.logger.log(
      `Daily AI mission sweep done in ${Date.now() - startedAt}ms ` +
        `(processed=${processed}, ensured=${generated})`,
    );
  }

  /**
   * Eligible = active, non-deleted, premium users. The daily AI mission is a
   * premium feature, so we only proactively generate for subscribers; free users
   * never hit the premium-gated GET anyway.
   */
  private fetchEligibleUsers(offset: number): Promise<User[]> {
    return this.userRepo.find({
      where: {
        status: 'active',
        deletedAt: IsNull(),
        isPremium: true,
      },
      select: ['id', 'timezone'],
      order: { id: 'ASC' },
      skip: offset,
      take: AiMissionScheduler.BATCH_SIZE,
    });
  }
}
