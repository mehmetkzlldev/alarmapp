import { InjectQueue } from '@nestjs/bullmq';
import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { Repository } from 'typeorm';
import { FirebaseService } from '../../integrations/firebase/firebase.service';
import { Device } from '../devices/device.entity';
import {
  NOTIFICATION_JOB,
  NOTIFICATIONS_QUEUE,
  SendPushJobData,
} from './notifications.constants';
import { NotificationLog } from './notification-log.entity';

export interface EnqueuePushParams {
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  channel?: string;
  scheduledAt?: Date | null;
  deviceId?: string | null;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(NotificationLog)
    private readonly logRepo: Repository<NotificationLog>,
    @InjectRepository(Device)
    private readonly deviceRepo: Repository<Device>,
    @InjectQueue(NOTIFICATIONS_QUEUE)
    private readonly queue: Queue<SendPushJobData>,
    private readonly firebase: FirebaseService,
  ) {}

  /**
   * Persist a notification_logs row in `queued` state and enqueue a BullMQ job.
   * Returns the created log so callers can correlate. The actual send happens in
   * the processor to keep the request path fast and to get retry semantics.
   */
  async enqueuePush(params: EnqueuePushParams): Promise<NotificationLog> {
    const tokens = await this.resolveTokens(params.userId);

    const log = this.logRepo.create({
      userId: params.userId,
      deviceId: params.deviceId ?? null,
      type: params.type,
      title: params.title,
      body: params.body,
      data: params.data ?? {},
      channel: params.channel ?? 'push',
      status: 'queued',
      scheduledAt: params.scheduledAt ?? null,
    });
    const saved = await this.logRepo.save(log);

    if (tokens.length === 0) {
      // No devices to target — mark failed immediately, skip the queue.
      saved.status = 'failed';
      saved.error = 'no_active_devices';
      await this.logRepo.save(saved);
      this.logger.warn(
        `enqueuePush: user ${params.userId} has no devices; marking ${saved.id} failed`,
      );
      return saved;
    }

    const jobData: SendPushJobData = {
      notificationLogId: saved.id,
      userId: params.userId,
      tokens,
      title: params.title,
      body: params.body,
      data: params.data,
    };

    // delay supports scheduled notifications (e.g. pre-alarm reminders).
    const delay =
      params.scheduledAt && params.scheduledAt.getTime() > Date.now()
        ? params.scheduledAt.getTime() - Date.now()
        : 0;

    await this.queue.add(NOTIFICATION_JOB.SEND_PUSH, jobData, {
      delay,
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      removeOnComplete: 1000,
      removeOnFail: 5000,
      // jobId keyed on the log id makes enqueue idempotent under retries.
      jobId: `push:${saved.id}`,
    });

    return saved;
  }

  /**
   * Perform the actual FCM send and transition the log row.
   * Called by the processor. Returns true on success so the worker can decide
   * whether to throw (and trigger a retry) on failure.
   */
  async deliver(job: SendPushJobData): Promise<boolean> {
    const log = await this.logRepo.findOne({
      where: { id: job.notificationLogId },
    });
    if (!log) {
      // Row was deleted (e.g. user deleted) — nothing to do, do not retry.
      this.logger.warn(
        `deliver: notification_log ${job.notificationLogId} not found; dropping`,
      );
      return true;
    }
    if (log.status === 'read' || log.status === 'delivered') {
      // Already terminal — avoid double send.
      return true;
    }

    try {
      const result = await this.firebase.sendPush({
        tokens: job.tokens,
        title: job.title,
        body: job.body,
        data: job.data,
      });

      // Clean up tokens FCM reported as permanently invalid.
      if (result.invalidTokens.length > 0) {
        await this.purgeInvalidTokens(job.userId, result.invalidTokens);
      }

      if (result.successCount > 0) {
        log.status = 'sent';
        log.fcmMessageId = result.messageIds[0] ?? null;
        log.sentAt = new Date();
        log.error = null;
        await this.logRepo.save(log);
        return true;
      }

      // Every token failed.
      log.status = 'failed';
      log.error = `fcm_all_failed (${result.failureCount})`;
      await this.logRepo.save(log);
      return false;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'unknown_error';
      log.status = 'failed';
      log.error = message.slice(0, 250);
      await this.logRepo.save(log);
      this.logger.error(`deliver failed for ${log.id}: ${message}`);
      // Signal failure so the worker can retry.
      return false;
    }
  }

  /** List the authenticated user's notifications, newest first. */
  async listForUser(
    userId: string,
    limit = 50,
    offset = 0,
  ): Promise<NotificationLog[]> {
    return this.logRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: Math.min(limit, 100),
      skip: offset,
    });
  }

  /** Mark a notification as read. Enforces ownership. */
  async markRead(userId: string, id: string): Promise<NotificationLog> {
    const log = await this.logRepo.findOne({ where: { id } });
    if (!log) throw new NotFoundException('Notification not found');
    if (log.userId !== userId) {
      throw new ForbiddenException('Not your notification');
    }
    if (log.status !== 'read') {
      log.status = 'read';
      log.readAt = new Date();
      await this.logRepo.save(log);
    }
    return log;
  }

  /** Resolve all active FCM tokens for a user. */
  private async resolveTokens(userId: string): Promise<string[]> {
    const devices = await this.deviceRepo.find({
      where: { userId },
      select: ['fcmToken'],
    });
    // De-duplicate to avoid sending twice to the same physical device.
    return [...new Set(devices.map((d) => d.fcmToken).filter(Boolean))];
  }

  /** Remove dead tokens flagged by FCM so we stop targeting them. */
  private async purgeInvalidTokens(
    userId: string,
    tokens: string[],
  ): Promise<void> {
    try {
      await this.deviceRepo
        .createQueryBuilder()
        .delete()
        .where('user_id = :userId', { userId })
        .andWhere('fcm_token IN (:...tokens)', { tokens })
        .execute();
      this.logger.log(
        `purged ${tokens.length} invalid FCM token(s) for user ${userId}`,
      );
    } catch (err) {
      // Cleanup is best-effort; never fail the send because of it.
      this.logger.warn(
        `failed to purge invalid tokens: ${
          err instanceof Error ? err.message : 'unknown'
        }`,
      );
    }
  }
}
