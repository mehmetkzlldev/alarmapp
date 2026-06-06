import {
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { existsSync } from 'fs';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

/**
 * Result of a multicast push send. `invalidTokens` contains the subset of the
 * provided tokens that the FCM backend reported as permanently unregistered
 * (e.g. app uninstalled, token rotated). Callers are expected to delete these
 * tokens from the `devices` table so we stop targeting dead endpoints.
 */
export interface SendPushResult {
  successCount: number;
  failureCount: number;
  /** FCM message ids for the successfully delivered messages, in input order. */
  messageIds: string[];
  /** Tokens that are no longer valid and should be purged from `devices`. */
  invalidTokens: string[];
}

export interface SendPushInput {
  tokens: string[];
  title: string;
  body: string;
  /**
   * Arbitrary data payload. FCM requires all data values to be strings, so any
   * non-string values are JSON/Stringified before dispatch.
   */
  data?: Record<string, unknown>;
}

/**
 * Thin wrapper around the firebase-admin SDK.
 *
 * Credentials are NEVER hardcoded. They are sourced (in priority order) from:
 *   1. FIREBASE_SERVICE_ACCOUNT      — full service-account JSON (string)
 *   2. FIREBASE_SERVICE_ACCOUNT_B64  — base64 of the service-account JSON
 *   3. GOOGLE_APPLICATION_CREDENTIALS — path handled implicitly by applicationDefault()
 *
 * This makes the same code work in local dev (file/path), CI, and prod (env).
 */
@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private app: admin.app.App | null = null;
  private enabled = false;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    this.initApp();
  }

  /**
   * Idempotent, NON-FATAL initialization. When Firebase credentials are not
   * configured (common in local dev), push + ID-token verification are disabled
   * but the application still boots. Never throws.
   */
  private initApp(): void {
    if (admin.apps.length > 0 && admin.apps[0]) {
      this.app = admin.apps[0];
      this.enabled = true;
      return;
    }

    const credential = this.resolveCredential();
    if (!credential) {
      this.logger.warn(
        'Firebase credentials not configured — push notifications and ID-token ' +
          'verification are DISABLED. Provide FIREBASE_SERVICE_ACCOUNT(_B64), the ' +
          'discrete FIREBASE_* fields, or a valid GOOGLE_APPLICATION_CREDENTIALS file to enable.',
      );
      this.app = null;
      this.enabled = false;
      return;
    }

    try {
      this.app = admin.initializeApp({
        credential,
        projectId: this.config.get<string>('FIREBASE_PROJECT_ID') || undefined,
      });
      this.enabled = true;
      this.logger.log('firebase-admin initialized');
    } catch (err) {
      this.logger.warn(
        `firebase-admin initialization failed — push/verify DISABLED: ${
          err instanceof Error ? err.message : 'unknown error'
        }`,
      );
      this.app = null;
      this.enabled = false;
    }
  }

  /**
   * Build an admin credential from environment without ever logging secrets.
   * Returns null (NOT throwing) when nothing usable is configured, so the app
   * can boot with Firebase disabled. Sources, in priority order:
   *   1. FIREBASE_SERVICE_ACCOUNT       — full service-account JSON
   *   2. FIREBASE_SERVICE_ACCOUNT_B64   — base64 of the JSON
   *   3. discrete FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY
   *   4. GOOGLE_APPLICATION_CREDENTIALS — only if the file actually exists
   */
  private resolveCredential(): admin.credential.Credential | null {
    const rawJson = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT');
    const b64Json = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_B64');

    let serviceAccount: admin.ServiceAccount | undefined;
    try {
      if (rawJson && rawJson.trim()) {
        serviceAccount = JSON.parse(rawJson) as admin.ServiceAccount;
      } else if (b64Json && b64Json.trim()) {
        serviceAccount = JSON.parse(
          Buffer.from(b64Json, 'base64').toString('utf8'),
        ) as admin.ServiceAccount;
      }
    } catch (err) {
      this.logger.error(
        'Failed to parse FIREBASE_SERVICE_ACCOUNT credential JSON',
        err instanceof Error ? err.stack : undefined,
      );
      return null;
    }

    if (serviceAccount) {
      return admin.credential.cert(serviceAccount);
    }

    // Discrete fields — only when all present and not the .env.example placeholders.
    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
    const privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');
    if (
      projectId &&
      clientEmail &&
      privateKey &&
      !clientEmail.includes('your-firebase') &&
      privateKey.includes('BEGIN PRIVATE KEY') &&
      !privateKey.includes('your-key')
    ) {
      return admin.credential.cert({
        projectId,
        clientEmail,
        privateKey: privateKey.replace(/\\n/g, '\n'),
      });
    }

    // Application-default — ONLY if GOOGLE_APPLICATION_CREDENTIALS points to a real file.
    const gac = this.config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');
    if (gac && gac.trim() && existsSync(gac)) {
      return admin.credential.applicationDefault();
    }

    return null;
  }

  /** True when Firebase credentials were successfully configured. */
  isEnabled(): boolean {
    return this.enabled;
  }

  private get application(): admin.app.App {
    if (!this.app) {
      this.initApp();
    }
    if (!this.app) {
      // Disabled in this environment — fail at call-time, not at boot.
      throw new ServiceUnavailableException(
        'Firebase is not configured on this server',
      );
    }
    return this.app;
  }

  /**
   * Verify a Firebase ID token (used for Google/Apple federated sign-in).
   * Throws UnauthorizedException on any verification failure so callers can map
   * directly to a 401 without leaking SDK internals.
   */
  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
    try {
      return await this.application.auth().verifyIdToken(idToken, true);
    } catch (err) {
      this.logger.warn(
        `verifyIdToken failed: ${err instanceof Error ? err.message : 'unknown'}`,
      );
      throw new UnauthorizedException('Invalid Firebase ID token');
    }
  }

  /**
   * Send a push notification to one or more device tokens.
   *
   * Uses sendEachForMulticast so a single bad token does not fail the whole
   * batch. The response is normalized into a SendPushResult that surfaces
   * permanently-invalid tokens for cleanup.
   */
  async sendPush(input: SendPushInput): Promise<SendPushResult> {
    const tokens = (input.tokens || []).filter(Boolean);
    if (tokens.length === 0) {
      return {
        successCount: 0,
        failureCount: 0,
        messageIds: [],
        invalidTokens: [],
      };
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: input.title,
        body: input.body,
      },
      data: this.stringifyData(input.data),
      android: {
        priority: 'high',
        notification: { sound: 'default', channelId: 'alarms' },
      },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: { aps: { sound: 'default', contentAvailable: true } },
      },
    };

    const response = await this.application
      .messaging()
      .sendEachForMulticast(message);

    const messageIds: string[] = [];
    const invalidTokens: string[] = [];

    response.responses.forEach((res, idx) => {
      if (res.success && res.messageId) {
        messageIds.push(res.messageId);
      } else if (res.error) {
        const code = res.error.code;
        // These error codes indicate the token is dead and should be removed.
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/invalid-argument'
        ) {
          invalidTokens.push(tokens[idx]);
        }
        this.logger.debug(`push failed for token[${idx}]: ${code}`);
      }
    });

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
      messageIds,
      invalidTokens,
    };
  }

  /** FCM data payloads must be string->string. Coerce non-string values safely. */
  private stringifyData(
    data?: Record<string, unknown>,
  ): Record<string, string> | undefined {
    if (!data) return undefined;
    const out: Record<string, string> = {};
    for (const [key, value] of Object.entries(data)) {
      if (value === null || value === undefined) continue;
      out[key] =
        typeof value === 'string' ? value : JSON.stringify(value);
    }
    return out;
  }
}
