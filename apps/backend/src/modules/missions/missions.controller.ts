import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import {
  GeneratedMathProblem,
  MathVerifyResult,
  MissionsService,
} from './missions.service';
import { MissionType } from './mission-type.entity';
import { MissionHistory } from './mission-history.entity';
import { GenerateMathDto } from './dto/generate-math.dto';
import { VerifyMathDto } from './dto/verify-math.dto';
import { CreateMissionHistoryDto } from './dto/create-mission-history.dto';

/**
 * Mission utilities: the mission-type catalog, the server-authoritative math
 * mission (generate/verify), and mission-attempt history. All routes require a
 * valid access token.
 */
@UseGuards(JwtAuthGuard)
@Controller('missions')
export class MissionsController {
  constructor(private readonly missionsService: MissionsService) {}

  @Get('types')
  getTypes(): Promise<MissionType[]> {
    return this.missionsService.findAllTypes();
  }

  @Post('math/generate')
  @HttpCode(HttpStatus.OK)
  generateMath(@Body() dto: GenerateMathDto): Promise<GeneratedMathProblem> {
    // Answer is cached server-side in Redis and intentionally not returned.
    return this.missionsService.generateMath(dto);
  }

  @Post('math/verify')
  @HttpCode(HttpStatus.OK)
  verifyMath(@Body() dto: VerifyMathDto): Promise<MathVerifyResult> {
    return this.missionsService.verifyMath(dto);
  }

  @Post('history')
  createHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateMissionHistoryDto,
  ): Promise<MissionHistory> {
    return this.missionsService.createHistory(user.id, dto);
  }
}
