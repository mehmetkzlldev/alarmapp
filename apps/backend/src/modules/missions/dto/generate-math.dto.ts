import { IsIn } from 'class-validator';
import { DIFFICULTIES, Difficulty } from '../../alarms/dto/create-alarm-mission.dto';

/** Body for POST /missions/math/generate. */
export class GenerateMathDto {
  @IsIn(DIFFICULTIES as unknown as string[])
  difficulty: Difficulty;
}
