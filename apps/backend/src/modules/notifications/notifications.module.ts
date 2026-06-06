import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FirebaseModule } from '../../integrations/firebase/firebase.module';
import { Device } from '../devices/device.entity';
import { NotificationLog } from './notification-log.entity';
import { NOTIFICATIONS_QUEUE } from './notifications.constants';
import { NotificationsController } from './notifications.controller';
import { NotificationsProcessor } from './notifications.processor';
import { NotificationsService } from './notifications.service';

/**
 * Registers:
 *  - NotificationLog entity (table notification_logs)
 *  - Device entity so we can resolve / purge a user's FCM tokens.
 *  - the 'notifications' BullMQ queue + its worker.
 *
 * FirebaseModule is @Global, but it is imported explicitly here for clarity.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([NotificationLog, Device]),
    BullModule.registerQueue({ name: NOTIFICATIONS_QUEUE }),
    FirebaseModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsProcessor],
  exports: [NotificationsService],
})
export class NotificationsModule {}
