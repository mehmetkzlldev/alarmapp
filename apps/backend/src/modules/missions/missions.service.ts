import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomUUID } from 'crypto';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../common/cache/cache.service';
import { MissionType } from './mission-type.entity';
import { MissionHistory } from './mission-history.entity';
import { GenerateMathDto } from './dto/generate-math.dto';
import { VerifyMathDto } from './dto/verify-math.dto';
import { CreateMissionHistoryDto } from './dto/create-mission-history.dto';
import { Difficulty } from '../alarms/dto/create-alarm-mission.dto';

/** How long a generated math problem stays solvable before it expires. */
const MATH_ANSWER_TTL_SEC = 600; // 10 minutes

export interface GeneratedMathProblem {
  problemId: string;
  expression: string;
  operandCount: number;
}

export interface MathVerifyResult {
  correct: boolean;
}

/**
 * Internal representation of a generated problem. We persist only the answer
 * (and a little metadata) in Redis so the client can never read it back.
 */
interface CachedMathProblem {
  answer: number;
  difficulty: Difficulty;
  expression: string;
}

@Injectable()
export class MissionsService {
  private readonly logger = new Logger(MissionsService.name);

  constructor(
    @InjectRepository(MissionType)
    private readonly missionTypesRepo: Repository<MissionType>,
    @InjectRepository(MissionHistory)
    private readonly historyRepo: Repository<MissionHistory>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  // ---------------------------------------------------------------------------
  // Mission types catalog
  // ---------------------------------------------------------------------------

  /** Public catalog of mission types, ordered by code for stable UIs. */
  findAllTypes(): Promise<MissionType[]> {
    return this.missionTypesRepo.find({ order: { code: 'ASC' } });
  }

  // ---------------------------------------------------------------------------
  // Math mission: generate + verify
  // ---------------------------------------------------------------------------

  private mathAnswerKey(problemId: string): string {
    return `mission:math:answer:${problemId}`;
  }

  /**
   * Generate a deterministic-by-difficulty math problem.
   *
   *  - easy:   2 small operands, + or -            (operands 1..20)
   *  - medium: 2-3 operands incl. * (×)            (operands 2..15, products bounded)
   *  - hard:   3 operands incl. * and ÷ (clean)    (larger ranges, integer division)
   *
   * The correct answer is stored in Redis under a random problemId with a TTL and
   * is NEVER returned to the client. Verification reads (and consumes) it.
   */
  async generateMath(dto: GenerateMathDto): Promise<GeneratedMathProblem> {
    const { expression, answer, operandCount } = this.buildMathProblem(
      dto.difficulty,
    );

    const problemId = randomUUID();
    const payload: CachedMathProblem = {
      answer,
      difficulty: dto.difficulty,
      expression,
    };

    // NX guards against the astronomically unlikely UUID collision; EX sets TTL.
    await this.redis.set(
      this.mathAnswerKey(problemId),
      JSON.stringify(payload),
      'EX',
      MATH_ANSWER_TTL_SEC,
      'NX',
    );

    return { problemId, expression, operandCount };
  }

  /**
   * Verify a submitted answer against the cached one.
   *
   * The cached answer is consumed atomically (GETDEL) so each problem is
   * single-use — a correct answer can't be replayed and a wrong answer can't be
   * brute-forced against the same problemId.
   */
  async verifyMath(dto: VerifyMathDto): Promise<MathVerifyResult> {
    const key = this.mathAnswerKey(dto.problemId);

    // GETDEL is atomic (Redis >= 6.2). Fall back to GET+DEL if unavailable.
    let raw: string | null;
    try {
      raw = await this.redis.getdel(key);
    } catch {
      raw = await this.redis.get(key);
      if (raw) await this.redis.del(key);
    }

    if (!raw) {
      // Unknown or expired problemId. Treat as incorrect rather than 404 so the
      // client flow (retry/regenerate) is uniform.
      return { correct: false };
    }

    let cached: CachedMathProblem;
    try {
      cached = JSON.parse(raw) as CachedMathProblem;
    } catch (err) {
      this.logger.error(
        `Corrupt cached math problem for ${dto.problemId}: ${(err as Error).message}`,
      );
      return { correct: false };
    }

    return { correct: cached.answer === dto.answer };
  }

  // ---------------------------------------------------------------------------
  // Mission history
  // ---------------------------------------------------------------------------

  /** Append a mission attempt outcome for the authenticated user. */
  async createHistory(
    userId: string,
    dto: CreateMissionHistoryDto,
  ): Promise<MissionHistory> {
    const entity = this.historyRepo.create({
      userId,
      alarmId: dto.alarmId ?? null,
      alarmMissionId: dto.alarmMissionId ?? null,
      missionType: dto.missionType,
      status: dto.status,
      attemptsCount: dto.attemptsCount ?? 1,
      durationSec: dto.durationSec ?? null,
      difficulty: dto.difficulty ?? null,
      metadata: dto.metadata ?? {},
    });
    return this.historyRepo.save(entity);
  }

  // ---------------------------------------------------------------------------
  // Deterministic math generator
  // ---------------------------------------------------------------------------

  /** Inclusive random integer in [min, max]. */
  private randInt(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  private pick<T>(arr: readonly T[]): T {
    return arr[this.randInt(0, arr.length - 1)];
  }

  /**
   * Build the expression string, its evaluated integer answer, and the operand
   * count, according to difficulty. Operators are restricted per tier and the
   * expression is evaluated left-to-right with standard precedence enforced by
   * how we construct it (no client-side eval — we compute the answer ourselves).
   */
  private buildMathProblem(difficulty: Difficulty): {
    expression: string;
    answer: number;
    operandCount: number;
  } {
    switch (difficulty) {
      case 'easy':
        return this.buildEasy();
      case 'hard':
        return this.buildHard();
      case 'medium':
      default:
        return this.buildMedium();
    }
  }

  /** easy: 2 small operands, addition or subtraction (non-negative result). */
  private buildEasy(): {
    expression: string;
    answer: number;
    operandCount: number;
  } {
    const op = this.pick(['+', '-'] as const);
    let a = this.randInt(1, 20);
    let b = this.randInt(1, 20);
    if (op === '-' && b > a) [a, b] = [b, a]; // keep result >= 0
    const answer = op === '+' ? a + b : a - b;
    return { expression: `${a} ${op} ${b}`, answer, operandCount: 2 };
  }

  /**
   * medium: 2-3 operands including multiplication.
   * We compute the answer ourselves respecting precedence (× before ±).
   */
  private buildMedium(): {
    expression: string;
    answer: number;
    operandCount: number;
  } {
    const operandCount = this.pick([2, 3] as const);

    if (operandCount === 2) {
      // a × b  OR  a ± b with a slightly larger range than easy.
      const op = this.pick(['+', '-', '*'] as const);
      if (op === '*') {
        const a = this.randInt(2, 12);
        const b = this.randInt(2, 12);
        return { expression: `${a} × ${b}`, answer: a * b, operandCount: 2 };
      }
      let a = this.randInt(5, 40);
      let b = this.randInt(5, 40);
      if (op === '-' && b > a) [a, b] = [b, a];
      return {
        expression: `${a} ${op} ${b}`,
        answer: op === '+' ? a + b : a - b,
        operandCount: 2,
      };
    }

    // 3 operands: a × b ± c  (multiplication binds first).
    const a = this.randInt(2, 12);
    const b = this.randInt(2, 12);
    const addSub = this.pick(['+', '-'] as const);
    const product = a * b;
    let c = this.randInt(1, 20);
    if (addSub === '-' && c > product) c = this.randInt(1, product); // result >= 0
    const answer = addSub === '+' ? product + c : product - c;
    return {
      expression: `${a} × ${b} ${addSub} ${c}`,
      answer,
      operandCount: 3,
    };
  }

  /**
   * hard: 3 operands including multiplication and (clean) division with larger
   * ranges. Division is constructed to always be exact integer division.
   */
  private buildHard(): {
    expression: string;
    answer: number;
    operandCount: number;
  } {
    const shape = this.pick(['mul_div', 'div_addsub', 'mul_addsub'] as const);

    if (shape === 'div_addsub') {
      // (a ÷ b) ± c  with a divisible by b.
      const b = this.randInt(2, 12);
      const quotient = this.randInt(2, 15);
      const a = b * quotient; // ensures exact division
      const addSub = this.pick(['+', '-'] as const);
      let c = this.randInt(1, 30);
      if (addSub === '-' && c > quotient) c = this.randInt(1, quotient);
      const answer = addSub === '+' ? quotient + c : quotient - c;
      return {
        expression: `${a} ÷ ${b} ${addSub} ${c}`,
        answer,
        operandCount: 3,
      };
    }

    if (shape === 'mul_div') {
      // a × b ÷ c  with (a×b) divisible by c. Build c from factors to stay clean.
      const a = this.randInt(3, 15);
      const b = this.randInt(3, 15);
      const product = a * b;
      const divisor = this.pickDivisor(product);
      return {
        expression: `${a} × ${b} ÷ ${divisor}`,
        answer: product / divisor,
        operandCount: 3,
      };
    }

    // mul_addsub: a × b ± c with larger ranges than medium.
    const a = this.randInt(6, 20);
    const b = this.randInt(6, 20);
    const addSub = this.pick(['+', '-'] as const);
    const product = a * b;
    let c = this.randInt(10, 60);
    if (addSub === '-' && c > product) c = this.randInt(1, product);
    const answer = addSub === '+' ? product + c : product - c;
    return {
      expression: `${a} × ${b} ${addSub} ${c}`,
      answer,
      operandCount: 3,
    };
  }

  /** Pick a random divisor (>1 when possible) of n that divides it exactly. */
  private pickDivisor(n: number): number {
    const divisors: number[] = [];
    for (let d = 2; d <= n; d++) {
      if (n % d === 0) divisors.push(d);
    }
    return divisors.length ? this.pick(divisors) : 1;
  }
}
