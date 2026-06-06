import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import type { DevicePlatform } from '../device.entity';

/** POST /devices body. */
export class RegisterDeviceDto {
  // FCM registration token (opaque, can be long).
  @IsString()
  @MinLength(1)
  @MaxLength(4096)
  fcmToken: string;

  @IsIn(['ios', 'android'], { message: 'platform must be ios or android' })
  platform: DevicePlatform;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  appVersion?: string;
}
