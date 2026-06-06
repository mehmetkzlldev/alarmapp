/** Name of the BullMQ queue used for outbound push notifications. */
export const NOTIFICATIONS_QUEUE = 'notifications';

/** Job names enqueued on NOTIFICATIONS_QUEUE. */
export const NOTIFICATION_JOB = {
  SEND_PUSH: 'send-push',
} as const;

/**
 * Payload carried by a 'send-push' job. We pass the notification_logs row id so
 * the worker can transition its status, plus the resolved tokens/content so the
 * worker does not need to re-query if nothing changed.
 */
export interface SendPushJobData {
  notificationLogId: string;
  userId: string;
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, unknown>;
}
