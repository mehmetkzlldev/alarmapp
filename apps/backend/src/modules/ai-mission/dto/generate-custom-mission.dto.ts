import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/**
 * Body for POST /ai-missions/custom — the premium "AI mission designer".
 * The user describes the kind of wake-up mission they want; Gemini designs one.
 */
export class GenerateCustomMissionDto {
  @IsString()
  @MinLength(3)
  @MaxLength(400)
  prompt!: string;

  @IsOptional()
  @IsIn(['easy', 'medium', 'hard'])
  difficulty?: 'easy' | 'medium' | 'hard';
}
