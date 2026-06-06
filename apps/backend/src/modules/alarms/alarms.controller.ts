import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { AlarmsService } from './alarms.service';
import { Alarm } from './alarm.entity';
import { AlarmMission } from './alarm-mission.entity';
import { CreateAlarmDto } from './dto/create-alarm.dto';
import { UpdateAlarmDto } from './dto/update-alarm.dto';
import { CreateAlarmMissionDto } from './dto/create-alarm-mission.dto';

/**
 * Alarm CRUD + nested mission management. All routes require a valid access
 * token; ownership is enforced in the service (every query is scoped to the
 * authenticated user id).
 */
@UseGuards(JwtAuthGuard)
@Controller('alarms')
export class AlarmsController {
  constructor(private readonly alarmsService: AlarmsService) {}

  @Get()
  findAll(@CurrentUser() user: AuthenticatedUser): Promise<Alarm[]> {
    return this.alarmsService.findAllForUser(user.id);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateAlarmDto,
  ): Promise<Alarm> {
    // isPremium drives the free-tier alarm-limit gate inside the service.
    return this.alarmsService.create(user.id, user.isPremium, dto);
  }

  @Get(':id')
  findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Alarm> {
    return this.alarmsService.findOneForUser(user.id, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAlarmDto,
  ): Promise<Alarm> {
    return this.alarmsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.alarmsService.remove(user.id, id);
  }

  @Patch(':id/toggle')
  toggle(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Alarm> {
    return this.alarmsService.toggle(user.id, id);
  }

  // ----- nested missions -----

  @Get(':id/missions')
  findMissions(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<AlarmMission[]> {
    return this.alarmsService.findMissionsForAlarm(user.id, id);
  }

  @Post(':id/missions')
  addMission(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateAlarmMissionDto,
  ): Promise<AlarmMission> {
    return this.alarmsService.addMission(user.id, id, dto);
  }

  @Delete(':id/missions/:missionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeMission(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('missionId', ParseUUIDPipe) missionId: string,
  ): Promise<void> {
    await this.alarmsService.removeMission(user.id, id, missionId);
  }
}
