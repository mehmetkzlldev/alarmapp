import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import {
  NOTIFICATION_JOB,
  NOTIFICATIONS_QUEUE,
  SendPushJobData,
} from './notifications.constants';
import { NotificationsService } from './notifications.service';

/**
 * BullMQ worker that consumes the 'notifications' queue and delivers pushes.
 *
 * Concurrency is bounded so a burst of alarm fires doesn't overwhelm FCM.
 * The processor throws on failure to leverage BullMQ's built-in retry/backoff
 * (configured at enqueue time); the service has already recorded the failure on
 * the notification_logs row.
 */
@Processor(NOTIFICATIONS_QUEUE, { concurrency: 10 })
export class NotificationsProcessor extends WorkerHost {
  private readonly logger = new Logger(NotificationsProcessor.name);

  constructor(private readonly notifications: NotificationsService) {
    super();
  }

  async process(job: Job<SendPushJobData>): Promise<void> {
    if (job.name !== NOTIFICATION_JOB.SEND_PUSH) {
      this.logger.warn(`Unknown job name: ${job.name}; skipping`);
      return;
    }

    const ok = await this.notifications.deliver(job.data);
    if (!ok) {
      // Throw so BullMQ retries with exponential backoff until attempts exhausted.
      throw new Error(
        `push delivery failed for notification ${job.data.notificationLogId}`,
      );
    }
    this.logger.debug(
      `push delivered for notification ${job.data.notificationLogId}`,
    );
  }
}
