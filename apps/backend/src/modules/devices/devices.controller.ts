import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { DevicesService } from './devices.service';
import { Device } from './device.entity';
import { RegisterDeviceDto } from './dto/register-device.dto';

/**
 * /api/v1/devices — FCM device registration.
 *
 * Auth is enforced by the per-controller JwtAuthGuard (no global guard);
 * a valid access token is required.
 */
@UseGuards(JwtAuthGuard)
@Controller('devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  /** POST /devices { fcmToken, platform, appVersion } -> Device (upsert) */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  register(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceDto,
  ): Promise<Device> {
    return this.devicesService.registerDevice(user.id, dto);
  }
}
