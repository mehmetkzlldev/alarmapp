import { IsInt, IsString, Length, Max, Min } from 'class-validator';

/** Body for POST /missions/math/verify. */
export class VerifyMathDto {
  /** Opaque id returned by /generate; used as the Redis key suffix. */
  @IsString()
  @Length(1, 64)
  problemId: string;

  /**
   * The user's numeric answer. Bounded to a sane integer range to reject garbage /
   * overflow without being clever about it.
   */
  @IsInt()
  @Min(-1_000_000)
  @Max(1_000_000)
  answer: number;
}
