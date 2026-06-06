import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Device } from './device.entity';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(
    @InjectRepository(Device)
    private readonly devicesRepo: Repository<Device>,
  ) {}

  /**
   * Idempotently register (or refresh) a device for a user.
   *
   * Uses an UPSERT keyed on the UNIQUE(user_id, fcm_token) constraint so the same
   * device re-registering only updates platform/app_version/last_active_at rather
   * than creating duplicate rows. The DB constraint is the source of truth — no
   * read-then-write race.
   */
  async registerDevice(userId: string, dto: RegisterDeviceDto): Promise<Device> {
    const now = new Date();

    await this.devicesRepo.upsert(
      {
        userId,
        fcmToken: dto.fcmToken,
        platform: dto.platform,
        appVersion: dto.appVersion ?? null,
        lastActiveAt: now,
      },
      {
        // Conflict target = the composite unique key; update mutable fields.
        conflictPaths: ['userId', 'fcmToken'],
        skipUpdateIfNoValuesChanged: false,
      },
    );

    // Return the canonical persisted row (upsert doesn't reliably return it
    // across drivers/versions, so re-read by the unique key).
    return this.devicesRepo.findOneOrFail({
      where: { userId, fcmToken: dto.fcmToken },
    });
  }

  /** List a user's registered devices (e.g. for fan-out push). */
  findByUser(userId: string): Promise<Device[]> {
    return this.devicesRepo.find({
      where: { userId },
      order: { lastActiveAt: 'DESC' },
    });
  }
}
