import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, IsNull, Repository } from 'typeorm';
import { DateTime } from 'luxon';
import { CacheService } from '../../common/cache/cache.service';
import { AppConfigService } from '../../config/app-config.service';
import { Alarm } from './alarm.entity';
import { AlarmMission } from './alarm-mission.entity';
import { CreateAlarmDto } from './dto/create-alarm.dto';
import { UpdateAlarmDto } from './dto/update-alarm.dto';
import { CreateAlarmMissionDto } from './dto/create-alarm-mission.dto';

/** Cache TTL for a user's alarm list. Short enough to bound staleness if an
 *  invalidation is ever missed; writes invalidate explicitly anyway. */
const ALARM_LIST_TTL_SEC = 300;

@Injectable()
export class AlarmsService {
  private readonly logger = new Logger(AlarmsService.name);

  constructor(
    @InjectRepository(Alarm)
    private readonly alarmsRepo: Repository<Alarm>,
    @InjectRepository(AlarmMission)
    private readonly missionsRepo: Repository<AlarmMission>,
    private readonly cache: CacheService,
    private readonly appConfig: AppConfigService,
    private readonly dataSource: DataSource,
  ) {}

  // ---------------------------------------------------------------------------
  // Cache helpers
  // ---------------------------------------------------------------------------

  private listCacheKey(userId: string): string {
    return `alarms:list:${userId}`;
  }

  private async invalidateList(userId: string): Promise<void> {
    await this.cache.del(this.listCacheKey(userId));
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /** List a user's (non-deleted) alarms, newest trigger first, with missions. */
  async findAllForUser(userId: string): Promise<Alarm[]> {
    const cacheKey = this.listCacheKey(userId);
    const cached = await this.cache.get<Alarm[]>(cacheKey);
    if (cached) return cached;

    const alarms = await this.alarmsRepo.find({
      where: { userId, deletedAt: IsNull() },
      relations: { missions: true },
      order: { createdAt: 'DESC' },
    });

    // Ensure nested missions are ordered deterministically for the client.
    for (const a of alarms) {
      a.missions?.sort((m1, m2) => m1.orderIndex - m2.orderIndex);
    }

    await this.cache.set(cacheKey, alarms, ALARM_LIST_TTL_SEC);
    return alarms;
  }

  /** Fetch a single alarm owned by the user, or throw 404. */
  async findOneForUser(userId: string, id: string): Promise<Alarm> {
    const alarm = await this.alarmsRepo.findOne({
      where: { id, userId, deletedAt: IsNull() },
      relations: { missions: true },
    });
    if (!alarm) {
      throw new NotFoundException('Alarm not found');
    }
    alarm.missions?.sort((a, b) => a.orderIndex - b.orderIndex);
    return alarm;
  }

  async findMissionsForAlarm(
    userId: string,
    alarmId: string,
  ): Promise<AlarmMission[]> {
    // Authorize ownership first.
    await this.findOneForUser(userId, alarmId);
    return this.missionsRepo.find({
      where: { alarmId },
      order: { orderIndex: 'ASC' },
    });
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /**
   * Create an alarm (with its missions) for a user.
   *
   * Free-tier enforcement: non-premium users may own at most `freeAlarmLimit`
   * active alarms. This is the "alarms beyond a free limit" premium gate — it is
   * conditional, so it lives here rather than in a route-level PremiumGuard.
   */
  async create(
    userId: string,
    isPremium: boolean,
    dto: CreateAlarmDto,
  ): Promise<Alarm> {
    await this.assertWithinFreeLimit(userId, isPremium);

    const timezone = dto.timezone ?? 'UTC';
    this.assertValidTimezone(timezone);
    const time = this.normalizeTime(dto.time);
    const repeatDays = this.normalizeRepeatDays(dto.repeatDays ?? []);
    const isActive = dto.isActive ?? true;

    const nextTriggerAt = isActive
      ? this.computeNextTriggerAt(time, timezone, repeatDays)
      : null;

    // Persist alarm + missions atomically so a bad mission can't leave a
    // half-created alarm behind.
    const saved = await this.dataSource.transaction(async (manager) => {
      const alarmRepo = manager.getRepository(Alarm);
      const missionRepo = manager.getRepository(AlarmMission);

      const alarm = alarmRepo.create({
        userId,
        label: dto.label ?? 'Alarm',
        time,
        timezone,
        repeatDays,
        isActive,
        sound: dto.sound ?? 'default',
        vibration: dto.vibration ?? true,
        volume: dto.volume ?? 80,
        gradualVolume: dto.gradualVolume ?? false,
        snoozeEnabled: dto.snoozeEnabled ?? true,
        snoozeIntervalMin: dto.snoozeIntervalMin ?? 5,
        snoozeLimit: dto.snoozeLimit ?? 3,
        nextTriggerAt,
      });
      const persisted = await alarmRepo.save(alarm);

      const missions = this.buildMissionEntities(
        persisted.id,
        dto.missions ?? [],
      );
      if (missions.length > 0) {
        await missionRepo.save(missions);
      }
      return persisted;
    });

    await this.invalidateList(userId);
    return this.findOneForUser(userId, saved.id);
  }

  /** Patch mutable alarm fields and recompute next_trigger_at when relevant. */
  async update(
    userId: string,
    id: string,
    dto: UpdateAlarmDto,
  ): Promise<Alarm> {
    const alarm = await this.findOneForUser(userId, id);

    if (dto.label !== undefined) alarm.label = dto.label;
    if (dto.time !== undefined) alarm.time = this.normalizeTime(dto.time);
    if (dto.timezone !== undefined) {
      this.assertValidTimezone(dto.timezone);
      alarm.timezone = dto.timezone;
    }
    if (dto.repeatDays !== undefined)
      alarm.repeatDays = this.normalizeRepeatDays(dto.repeatDays);
    if (dto.isActive !== undefined) alarm.isActive = dto.isActive;
    if (dto.sound !== undefined) alarm.sound = dto.sound;
    if (dto.vibration !== undefined) alarm.vibration = dto.vibration;
    if (dto.volume !== undefined) alarm.volume = dto.volume;
    if (dto.gradualVolume !== undefined) alarm.gradualVolume = dto.gradualVolume;
    if (dto.snoozeEnabled !== undefined)
      alarm.snoozeEnabled = dto.snoozeEnabled;
    if (dto.snoozeIntervalMin !== undefined)
      alarm.snoozeIntervalMin = dto.snoozeIntervalMin;
    if (dto.snoozeLimit !== undefined) alarm.snoozeLimit = dto.snoozeLimit;

    // Recompute the next trigger whenever scheduling inputs change.
    alarm.nextTriggerAt = alarm.isActive
      ? this.computeNextTriggerAt(
          alarm.time,
          alarm.timezone,
          alarm.repeatDays,
        )
      : null;

    await this.alarmsRepo.save(alarm);
    await this.invalidateList(userId);
    return this.findOneForUser(userId, id);
  }

  /** Flip is_active and recompute/clear next_trigger_at accordingly. */
  async toggle(userId: string, id: string): Promise<Alarm> {
    const alarm = await this.findOneForUser(userId, id);
    alarm.isActive = !alarm.isActive;
    alarm.nextTriggerAt = alarm.isActive
      ? this.computeNextTriggerAt(alarm.time, alarm.timezone, alarm.repeatDays)
      : null;
    await this.alarmsRepo.save(alarm);
    await this.invalidateList(userId);
    return this.findOneForUser(userId, id);
  }

  /** Soft-delete the alarm (sets deleted_at). */
  async remove(userId: string, id: string): Promise<void> {
    const alarm = await this.findOneForUser(userId, id);
    await this.alarmsRepo.softRemove(alarm);
    await this.invalidateList(userId);
  }

  // ----- nested missions -----

  async addMission(
    userId: string,
    alarmId: string,
    dto: CreateAlarmMissionDto,
  ): Promise<AlarmMission> {
    await this.findOneForUser(userId, alarmId); // ownership check

    // Guard the UNIQUE(alarm_id, order_index) invariant with a friendly 400
    // instead of leaking a raw DB unique-violation.
    const clash = await this.missionsRepo.findOne({
      where: { alarmId, orderIndex: dto.orderIndex ?? 0 },
    });
    if (clash) {
      throw new BadRequestException(
        `A mission already exists at orderIndex ${dto.orderIndex ?? 0}`,
      );
    }

    const [entity] = this.buildMissionEntities(alarmId, [dto]);
    const saved = await this.missionsRepo.save(entity);
    await this.invalidateList(userId);
    return saved;
  }

  async removeMission(
    userId: string,
    alarmId: string,
    missionId: string,
  ): Promise<void> {
    await this.findOneForUser(userId, alarmId); // ownership check
    const mission = await this.missionsRepo.findOne({
      where: { id: missionId, alarmId },
    });
    if (!mission) {
      throw new NotFoundException('Mission not found for this alarm');
    }
    await this.missionsRepo.remove(mission);
    await this.invalidateList(userId);
  }

  // ---------------------------------------------------------------------------
  // Domain helpers
  // ---------------------------------------------------------------------------

  /** Throw 403 if a non-premium user is at/over the free alarm limit. */
  private async assertWithinFreeLimit(
    userId: string,
    isPremium: boolean,
  ): Promise<void> {
    if (isPremium) return;
    const limit = this.appConfig.freeAlarmLimit;
    const count = await this.alarmsRepo.count({
      where: { userId, deletedAt: IsNull() },
    });
    if (count >= limit) {
      throw new ForbiddenException(
        `Free plan is limited to ${limit} alarms. Upgrade to premium for unlimited alarms.`,
      );
    }
  }

  private buildMissionEntities(
    alarmId: string,
    missions: CreateAlarmMissionDto[],
  ): AlarmMission[] {
    // Reject duplicate orderIndex values inside a single request up-front.
    const seen = new Set<number>();
    return missions.map((m) => {
      const orderIndex = m.orderIndex ?? 0;
      if (seen.has(orderIndex)) {
        throw new BadRequestException(
          `Duplicate mission orderIndex ${orderIndex}`,
        );
      }
      seen.add(orderIndex);
      return this.missionsRepo.create({
        alarmId,
        missionType: m.missionType,
        difficulty: m.difficulty ?? 'medium',
        orderIndex,
        config: m.config ?? {},
      });
    });
  }

  /** Normalize "HH:mm" -> "HH:mm:ss" for the Postgres `time` column. */
  private normalizeTime(time: string): string {
    return time.length === 5 ? `${time}:00` : time;
  }

  /** De-duplicate and sort weekday indices for a stable representation. */
  private normalizeRepeatDays(days: number[]): number[] {
    return Array.from(new Set(days)).sort((a, b) => a - b);
  }

  private assertValidTimezone(timezone: string): void {
    if (!DateTime.local().setZone(timezone).isValid) {
      throw new BadRequestException(`Unknown timezone: ${timezone}`);
    }
  }

  /**
   * Compute the next UTC instant the alarm should fire.
   *
   * Algorithm (all wall-clock math done in the alarm's own timezone):
   *  - Parse the HH:mm[:ss] time of day.
   *  - If repeatDays is empty (one-shot): pick today at that time if still in the
   *    future, else tomorrow.
   *  - If repeatDays is set: scan the next 7 days (including today) for the first
   *    day whose weekday is in the set AND whose resolved instant is in the future.
   *
   * Returns a JS Date (UTC instant) or null if somehow unresolved (defensive).
   *
   * Weekday convention: our repeat_days uses 0=Sun..6=Sat. Luxon's `weekday` is
   * 1=Mon..7=Sun, so we map via `luxonToSun0`.
   */
  computeNextTriggerAt(
    time: string,
    timezone: string,
    repeatDays: number[],
  ): Date | null {
    const [hh, mm, ss] = time.split(':').map((p) => parseInt(p, 10));
    const now = DateTime.now().setZone(timezone);
    if (!now.isValid) {
      throw new BadRequestException(`Unknown timezone: ${timezone}`);
    }

    const atTimeOnDay = (base: DateTime): DateTime =>
      base.set({ hour: hh, minute: mm, second: ss || 0, millisecond: 0 });

    // One-shot alarm.
    if (repeatDays.length === 0) {
      let candidate = atTimeOnDay(now);
      if (candidate <= now) {
        candidate = candidate.plus({ days: 1 });
      }
      return candidate.toUTC().toJSDate();
    }

    const repeatSet = new Set(this.normalizeRepeatDays(repeatDays));

    // Look ahead up to 7 days (today + 6) to find the next matching weekday.
    for (let offset = 0; offset < 8; offset++) {
      const day = now.plus({ days: offset });
      const sun0Weekday = this.luxonToSun0(day.weekday);
      if (!repeatSet.has(sun0Weekday)) continue;

      const candidate = atTimeOnDay(day);
      // For offset 0 (today) only accept if still in the future.
      if (offset === 0 && candidate <= now) continue;
      return candidate.toUTC().toJSDate();
    }

    // Should be unreachable given a non-empty set, but stay defensive.
    this.logger.warn(
      `Could not resolve next_trigger_at for time=${time} tz=${timezone} days=${repeatDays}`,
    );
    return null;
  }

  /** Map luxon weekday (1=Mon..7=Sun) to our 0=Sun..6=Sat convention. */
  private luxonToSun0(luxonWeekday: number): number {
    // luxon: Mon=1..Sun=7  ->  ours: Sun=0,Mon=1..Sat=6
    return luxonWeekday === 7 ? 0 : luxonWeekday;
  }
}
