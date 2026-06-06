import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { GeminiService } from '../../integrations/gemini/gemini.service';
import { CacheService } from '../../common/cache/cache.service';
import { User } from '../users/user.entity';
import {
  isSupportedObject,
  SUPPORTED_OBJECTS,
} from '../object-detection/object-detection.constants';
import { DailyAiMission } from './ai-mission.entity';
import { TodayMissionDto } from './dto/today-mission.dto';
import { CompleteMissionResponseDto } from './dto/complete-mission.dto';
import { endOfLocalDayUtc, localDateString } from './ai-mission.util';

type Difficulty = 'easy' | 'medium' | 'hard';

/** Strict JSON schema for the daily mission generator. */
const MISSION_SCHEMA = {
  type: 'object',
  properties: {
    missionType: {
      type: 'string',
      enum: ['object_detection', 'photo'],
      description:
        'object_detection when targeting one of the supported objects; ' +
        'photo for free-form "take a picture of X" missions.',
    },
    difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'] },
    instruction: {
      type: 'string',
      description: 'Short, friendly imperative shown to the half-asleep user.',
    },
    targetObject: {
      type: 'string',
      description:
        'Required when missionType=object_detection; one of the supported objects.',
      nullable: true,
    },
  },
  required: ['missionType', 'difficulty', 'instruction'],
} as const;

interface RawMission {
  missionType: 'object_detection' | 'photo';
  difficulty: Difficulty;
  instruction: string;
  targetObject?: string | null;
}

@Injectable()
export class AiMissionService {
  private readonly logger = new Logger(AiMissionService.name);

  /** Redis cache TTL for a generated mission (covers a full local day). */
  private static readonly CACHE_TTL_SEC = 60 * 60 * 26; // 26h slack for DST

  constructor(
    private readonly gemini: GeminiService,
    private readonly cache: CacheService,
    @InjectRepository(DailyAiMission)
    private readonly missionRepo: Repository<DailyAiMission>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  // ---------------------------------------------------------------------------
  // Read path (GET /ai-missions/today)
  // ---------------------------------------------------------------------------

  /**
   * Return today's mission for the user, generating it on demand if the
   * scheduler has not produced one yet (lazy fallback). Result is cached in
   * Redis keyed by user+localDate.
   *
   * The user's timezone is resolved server-side (the JWT principal does not
   * carry it) so "today" is correct in the user's local time.
   */
  async getToday(userId: string): Promise<TodayMissionDto> {
    const timezone = await this.resolveTimezone(userId);
    const date = localDateString(timezone);
    const cacheKey = this.cacheKey(userId, date);

    const cached = await this.cache.get<TodayMissionDto>(cacheKey);
    if (cached) {
      return cached;
    }

    const mission = await this.getOrCreateForDate(userId, timezone, date);
    const dto = this.toDto(mission, timezone);
    await this.cache.set(cacheKey, dto, AiMissionService.CACHE_TTL_SEC);
    return dto;
  }

  // ---------------------------------------------------------------------------
  // Write path (used by both lazy fallback and the scheduler)
  // ---------------------------------------------------------------------------

  /**
   * Idempotently ensure a mission row exists for (user, localDate). Safe to call
   * concurrently: relies on the UNIQUE(user_id, date) constraint and re-reads on
   * conflict so the scheduler and an on-demand GET never duplicate.
   */
  async getOrCreateForDate(
    userId: string,
    timezone: string,
    date: string,
  ): Promise<DailyAiMission> {
    const existing = await this.missionRepo.findOne({
      where: { userId, date },
    });
    if (existing) return existing;

    const generated = await this.generateMission(userId);

    const entity = this.missionRepo.create({
      userId,
      date,
      missionType:
        generated.data.missionType === 'object_detection'
          ? 'object_detection'
          : 'photo',
      difficulty: generated.data.difficulty,
      instruction: generated.data.instruction,
      targetObject: generated.data.targetObject ?? null,
      generatedContent: generated.data as unknown as Record<string, unknown>,
      status: 'assigned',
      geminiRequestId: generated.requestId,
    });

    try {
      return await this.missionRepo.save(entity);
    } catch (err) {
      // Unique violation => another worker won the race; return the winner.
      if (this.isUniqueViolation(err)) {
        const winner = await this.missionRepo.findOne({
          where: { userId, date },
        });
        if (winner) return winner;
      }
      throw err;
    }
  }

  /**
   * Ask Gemini for a fresh daily mission as strict JSON, then sanitize. We never
   * trust raw model output: we validate the enum, clamp the target object to the
   * supported list, and provide a deterministic fallback if generation fails.
   */
  private async generateMission(userId: string) {
    const prompt = this.buildPrompt();
    const result = await this.gemini.generateJson<RawMission>(
      prompt,
      MISSION_SCHEMA as unknown as Record<string, unknown>,
      { temperature: 0.9 }, // a little variety day to day
    );

    const sanitized = this.sanitize(result.data);
    this.logger.log(
      `Generated daily mission user=${userId} type=${sanitized.missionType} ` +
        `difficulty=${sanitized.difficulty} target=${sanitized.targetObject ?? '-'}`,
    );
    return { data: sanitized, requestId: result.requestId };
  }

  private buildPrompt(): string {
    return [
      'Generate ONE short wake-up mission for an alarm app that forces a',
      'half-asleep user to physically get out of bed and move around.',
      'It must require walking to another room or finding/photographing a',
      'real object. Keep the instruction friendly and under 12 words.',
      '',
      'Prefer missionType="object_detection" with one of these targetObject',
      `values: ${SUPPORTED_OBJECTS.join(', ')}.`,
      'Otherwise use missionType="photo" for creative tasks like',
      '"Take a picture of a plant" or "Find something blue".',
      '',
      'Difficulty scales complexity:',
      ' - easy: a single common object near the bed (e.g. "Find your keys").',
      ' - medium: an object in another room (e.g. "Find a toothbrush").',
      ' - hard: a multi-step or abstract task (e.g. "Take a picture of a plant",',
      '   "Find something blue and photograph it").',
      'Examples: "Find a spoon", "Find a toothbrush", "Find something blue",',
      '"Take a picture of a plant".',
      'Pick a difficulty at random with a slight bias toward medium.',
    ].join(' ');
  }

  /** Validate + clamp model output to our supported space. */
  private sanitize(raw: RawMission): RawMission {
    const difficulty: Difficulty = (['easy', 'medium', 'hard'] as const).includes(
      raw?.difficulty,
    )
      ? raw.difficulty
      : 'medium';

    let missionType: RawMission['missionType'] =
      raw?.missionType === 'object_detection' ? 'object_detection' : 'photo';

    let targetObject: string | null =
      typeof raw?.targetObject === 'string'
        ? raw.targetObject.trim().toLowerCase()
        : null;

    // If it claims object_detection but the target isn't supported, downgrade to
    // a free-form photo mission so the client never gets an unverifiable target.
    if (missionType === 'object_detection') {
      if (!targetObject || !isSupportedObject(targetObject)) {
        missionType = 'photo';
        targetObject = null;
      }
    } else {
      targetObject = null;
    }

    const instruction =
      typeof raw?.instruction === 'string' && raw.instruction.trim().length
        ? raw.instruction.trim().slice(0, 140)
        : this.fallbackInstruction(missionType, targetObject);

    return { missionType, difficulty, instruction, targetObject };
  }

  private fallbackInstruction(
    missionType: RawMission['missionType'],
    target: string | null,
  ): string {
    if (missionType === 'object_detection' && target) {
      return `Find a ${target} and photograph it`;
    }
    return 'Take a picture of something blue';
  }

  // ---------------------------------------------------------------------------
  // Complete path (POST /ai-missions/:id/complete)
  // ---------------------------------------------------------------------------

  async complete(
    userId: string,
    missionId: string,
    imageS3Key: string | undefined,
  ): Promise<CompleteMissionResponseDto> {
    const mission = await this.missionRepo.findOne({
      where: { id: missionId, userId },
    });
    if (!mission) {
      throw new NotFoundException('Mission not found');
    }

    const timezone = await this.resolveTimezone(userId);

    // Reject completion of a stale (previous-day) mission.
    const today = localDateString(timezone);
    if (mission.date !== today) {
      if (mission.status !== 'completed') {
        mission.status = 'expired';
        await this.missionRepo.save(mission);
      }
      return { status: 'expired' };
    }

    if (mission.status === 'completed') {
      return { status: 'completed' };
    }

    mission.status = 'completed';
    mission.completedAt = new Date();
    if (imageS3Key) {
      mission.generatedContent = {
        ...mission.generatedContent,
        completionImageS3Key: imageS3Key,
      };
    }
    await this.missionRepo.save(mission);

    // Invalidate cache so a subsequent GET reflects the completed status.
    await this.cache.del(this.cacheKey(userId, mission.date));

    return { status: 'completed' };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /** Resolve a user's timezone (defaults to UTC if the user is gone). */
  private async resolveTimezone(userId: string): Promise<string> {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      select: ['id', 'timezone'],
    });
    return user?.timezone || 'UTC';
  }

  private toDto(mission: DailyAiMission, timezone: string): TodayMissionDto {
    return {
      id: mission.id,
      missionType: mission.missionType,
      difficulty: mission.difficulty as Difficulty,
      instruction: mission.instruction,
      ...(mission.targetObject ? { targetObject: mission.targetObject } : {}),
      expiresAt: endOfLocalDayUtc(timezone).toISOString(),
    };
  }

  private cacheKey(userId: string, date: string): string {
    return `ai-mission:${userId}:${date}`;
  }

  private isUniqueViolation(err: unknown): boolean {
    // Postgres unique_violation error code.
    return (err as { code?: string })?.code === '23505';
  }
}
