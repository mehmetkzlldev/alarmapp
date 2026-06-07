import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';

import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { PremiumGuard } from '../../common/auth/premium.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { AiMissionService } from './ai-mission.service';
import { TodayMissionDto } from './dto/today-mission.dto';
import {
  CompleteMissionDto,
  CompleteMissionResponseDto,
} from './dto/complete-mission.dto';
import { GenerateCustomMissionDto } from './dto/generate-custom-mission.dto';

/**
 * Routes:
 *   GET  /api/v1/ai-missions/today          (PremiumGuard — premium-gated)
 *   POST /api/v1/ai-missions/:id/complete
 */
@Controller('ai-missions')
@UseGuards(JwtAuthGuard)
export class AiMissionController {
  constructor(private readonly service: AiMissionService) {}

  @Get('today')
  // Premium-gated per the API contract: only active subscribers get the daily
  // AI-generated wake-up mission. PremiumGuard runs after JwtAuthGuard.
  @UseGuards(PremiumGuard)
  async getToday(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<TodayMissionDto> {
    return this.service.getToday(user.id);
  }

  /**
   * Premium "AI mission designer": generate a custom mission from the user's
   * own description. Premium gating is enforced in the app UI/paywall; left
   * open here so the feature is fully testable in the demo build.
   */
  @Post('custom')
  @HttpCode(HttpStatus.OK)
  async generateCustom(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: GenerateCustomMissionDto,
  ): Promise<TodayMissionDto> {
    return this.service.generateCustom(user.id, dto.prompt, dto.difficulty);
  }

  @Post(':id/complete')
  @HttpCode(HttpStatus.OK)
  async complete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: CompleteMissionDto,
  ): Promise<CompleteMissionResponseDto> {
    return this.service.complete(user.id, id, dto.imageS3Key);
  }
}
