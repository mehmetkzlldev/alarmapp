/**
 * Response for GET /ai-missions/today (mirrors the API contract).
 */
export class TodayMissionDto {
  id!: string;
  missionType!: string;
  difficulty!: 'easy' | 'medium' | 'hard';
  instruction!: string;
  /** Only for object-detection style missions. */
  targetObject?: string;
  /** ISO timestamp when this mission expires (end of the user's local day). */
  expiresAt!: string;
}
