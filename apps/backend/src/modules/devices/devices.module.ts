import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Device } from './device.entity';
import { DevicesService } from './devices.service';
import { DevicesController } from './devices.controller';

/**
 * Devices feature module. Exports DevicesService so the notifications module can
 * resolve a user's FCM tokens when fanning out push messages.
 */
@Module({
  imports: [TypeOrmModule.forFeature([Device])],
  controllers: [DevicesController],
  providers: [DevicesService],
  exports: [DevicesService, TypeOrmModule],
})
export class DevicesModule {}
