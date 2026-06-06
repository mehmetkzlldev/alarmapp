import {
  BadRequestException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { RedisService } from '../../integrations/redis/redis.service';
import { User } from '../users/user.entity';
import { ValidateReceiptDto } from './dto/validate-receipt.dto';
import {
  Plan,
  PLANS,
  PREMIUM_PLAN_CODES,
  resolvePlanByProductId,
} from './plans.constant';
import {
  AppleVerifier,
  GooglePlayVerifier,
  VerifiedReceipt,
} from './receipt-verifiers';
import {
  Subscription,
  SubscriptionPlan,
  SubscriptionStatus,
} from './subscription.entity';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);
  private readonly cacheTtlSec = 300; // 5 min cache for status reads.

  constructor(
    @InjectRepository(Subscription)
    private readonly subRepo: Repository<Subscription>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
    private readonly redis: RedisService,
    private readonly config: ConfigService,
  ) {}

  /** GET /subscriptions/plans */
  getPlans(): Plan[] {
    return PLANS;
  }

  /** GET /subscriptions/me — returns the user's subscription (creating a free default if missing). */
  async getForUser(userId: string): Promise<Subscription> {
    const cached = await this.readCache(userId);
    if (cached) return cached;

    let sub = await this.subRepo.findOne({ where: { userId } });
    if (!sub) {
      sub = await this.subRepo.save(
        this.subRepo.create({ userId, plan: 'free', status: 'inactive' }),
      );
    }
    await this.writeCache(sub);
    return sub;
  }

  /**
   * POST /subscriptions/validate
   *
   * Validates a store receipt SERVER-SIDE (never trusting the client for
   * entitlement), then applies the result idempotently keyed on
   * original_transaction_id. Premium flags on the user row are updated in the
   * same DB transaction so they can never diverge from the subscription row.
   */
  async validateReceipt(
    userId: string,
    dto: ValidateReceiptDto,
  ): Promise<Subscription> {
    const planCode = resolvePlanByProductId(dto.store, dto.productId);
    if (!planCode || planCode === 'free') {
      throw new BadRequestException('Unknown or non-premium product id');
    }

    const verified = await this.verifyWithStore(dto);

    // Idempotency: if we've already recorded this exact period for this
    // original_transaction_id, return the existing state without re-applying.
    const existing = await this.subRepo.findOne({
      where: { originalTransactionId: verified.originalTransactionId },
    });
    if (
      existing &&
      existing.userId === userId &&
      existing.storeSubscriptionId === verified.storeSubscriptionId &&
      existing.currentPeriodEnd?.getTime() ===
        verified.currentPeriodEnd.getTime()
    ) {
      this.logger.debug(
        `validateReceipt: idempotent no-op for txn ${verified.originalTransactionId}`,
      );
      return existing;
    }

    const status = this.deriveStatus(verified);
    const updated = await this.applyEntitlement(
      userId,
      dto.store,
      planCode,
      status,
      verified,
    );
    await this.invalidateCache(userId);
    await this.writeCache(updated);
    return updated;
  }

  /**
   * Handle a Google Real-Time Developer Notification (RTDN).
   * The push payload contains a base64 message with subscriptionNotification.
   * We re-verify with the Play API to get the authoritative state.
   */
  async handleGoogleNotification(
    notification: GoogleRtdnEnvelope,
  ): Promise<void> {
    const decoded = this.decodeGooglePubSub(notification);
    if (!decoded?.subscriptionNotification) {
      this.logger.debug('RTDN without subscriptionNotification; ignoring');
      return;
    }
    const { subscriptionId, purchaseToken } = decoded.subscriptionNotification;
    try {
      const verifier = this.googleVerifier();
      const verified = await verifier.verify(subscriptionId, purchaseToken);
      await this.applyFromWebhook('play_store', verified);
    } catch (err) {
      this.logger.error(
        `Failed to process Google RTDN: ${
          err instanceof Error ? err.message : 'unknown'
        }`,
      );
    }
  }

  /**
   * Handle an App Store Server Notification (V2 signedPayload).
   * We decode the signed payload's transaction info and apply state.
   */
  async handleAppleNotification(signedPayload: string): Promise<void> {
    try {
      const verifier = this.appleVerifier();
      // The signed transaction (JWS) is carried inside the notification; here we
      // verify it directly to extract authoritative subscription state.
      const verified = await verifier.verify(signedPayload);
      await this.applyFromWebhook('app_store', verified);
    } catch (err) {
      this.logger.error(
        `Failed to process Apple notification: ${
          err instanceof Error ? err.message : 'unknown'
        }`,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  private async verifyWithStore(
    dto: ValidateReceiptDto,
  ): Promise<VerifiedReceipt> {
    if (dto.store === 'play_store') {
      const verifier = this.googleVerifier();
      // For Google, the client sends the purchaseToken as `receipt`.
      return verifier.verify(dto.productId, dto.receipt);
    }
    const verifier = this.appleVerifier();
    return verifier.verify(dto.receipt);
  }

  private googleVerifier(): GooglePlayVerifier {
    const pkg = this.config.get<string>('ANDROID_PACKAGE_NAME');
    if (!pkg) {
      throw new BadRequestException('Google Play verification not configured');
    }
    const sa =
      this.config.get<string>('GOOGLE_PLAY_SERVICE_ACCOUNT') ||
      this.decodeB64Env('GOOGLE_PLAY_SERVICE_ACCOUNT_B64');
    return new GooglePlayVerifier(pkg, sa);
  }

  private appleVerifier(): AppleVerifier {
    const secret = this.config.get<string>('APPLE_IAP_SHARED_SECRET');
    if (!secret) {
      throw new BadRequestException('Apple IAP verification not configured');
    }
    return new AppleVerifier(secret);
  }

  private decodeB64Env(key: string): string | undefined {
    const v = this.config.get<string>(key);
    return v ? Buffer.from(v, 'base64').toString('utf8') : undefined;
  }

  /** Map a verified receipt onto our subscription status enum. */
  private deriveStatus(v: VerifiedReceipt): SubscriptionStatus {
    if (v.isTrial && v.isActive) return 'trial';
    if (v.isActive) return 'active';
    // Past expiry but still flagged auto-renew => grace period.
    if (v.autoRenew) return 'grace_period';
    return 'expired';
  }

  /**
   * Apply entitlement transactionally: upsert the subscriptions row and sync the
   * users.is_premium / premium_until columns so they cannot diverge.
   */
  private async applyEntitlement(
    userId: string,
    store: 'app_store' | 'play_store',
    plan: SubscriptionPlan,
    status: SubscriptionStatus,
    verified: VerifiedReceipt,
  ): Promise<Subscription> {
    return this.dataSource.transaction(async (manager) => {
      const subRepo = manager.getRepository(Subscription);
      let sub = await subRepo.findOne({ where: { userId } });
      if (!sub) {
        sub = subRepo.create({ userId });
      }
      sub.plan = plan;
      sub.store = store;
      sub.storeSubscriptionId = verified.storeSubscriptionId;
      sub.originalTransactionId = verified.originalTransactionId;
      sub.status = status;
      sub.startedAt = verified.startedAt;
      sub.currentPeriodEnd = verified.currentPeriodEnd;
      sub.autoRenew = verified.autoRenew;
      sub.latestReceipt = verified.raw;
      const saved = await subRepo.save(sub);

      // Sync the denormalized premium flags on the user row.
      const isPremium = PREMIUM_PLAN_CODES.includes(plan) && verified.isActive;
      await manager.getRepository(User).update(
        { id: userId },
        {
          isPremium,
          premiumUntil: isPremium ? verified.currentPeriodEnd : null,
        },
      );

      return saved;
    });
  }

  /**
   * Webhook path: locate the subscription by original_transaction_id and
   * re-apply state. Idempotent on the same period.
   */
  private async applyFromWebhook(
    store: 'app_store' | 'play_store',
    verified: VerifiedReceipt,
  ): Promise<void> {
    const existing = await this.subRepo.findOne({
      where: { originalTransactionId: verified.originalTransactionId },
    });
    if (!existing) {
      // We have no user mapping for this transaction yet (validate not called).
      this.logger.warn(
        `Webhook for unknown txn ${verified.originalTransactionId}; ignoring until client validates`,
      );
      return;
    }
    const status = this.deriveStatus(verified);
    await this.applyEntitlement(
      existing.userId,
      store,
      existing.plan,
      status,
      verified,
    );
    await this.invalidateCache(existing.userId);
  }

  // ----- Redis cache helpers (status caching with explicit invalidation) -----

  private cacheKey(userId: string): string {
    return `sub:status:${userId}`;
  }

  private async readCache(userId: string): Promise<Subscription | null> {
    try {
      const raw = await this.redis.get(this.cacheKey(userId));
      if (!raw) return null;
      const obj = JSON.parse(raw) as Subscription;
      // Revive dates that JSON flattened to strings.
      if (obj.currentPeriodEnd)
        obj.currentPeriodEnd = new Date(obj.currentPeriodEnd);
      if (obj.startedAt) obj.startedAt = new Date(obj.startedAt);
      return obj;
    } catch {
      return null;
    }
  }

  private async writeCache(sub: Subscription): Promise<void> {
    try {
      await this.redis.set(
        this.cacheKey(sub.userId),
        JSON.stringify(sub),
        this.cacheTtlSec,
      );
    } catch {
      // Cache write failures are non-fatal.
    }
  }

  private async invalidateCache(userId: string): Promise<void> {
    try {
      await this.redis.del(this.cacheKey(userId));
    } catch {
      // Ignore.
    }
  }

  // ----- Webhook payload decoding -----

  private decodeGooglePubSub(
    envelope: GoogleRtdnEnvelope,
  ): GoogleDeveloperNotification | null {
    try {
      const data = envelope?.message?.data;
      if (!data) return null;
      return JSON.parse(
        Buffer.from(data, 'base64').toString('utf8'),
      ) as GoogleDeveloperNotification;
    } catch (err) {
      this.logger.warn(
        `Failed to decode Google Pub/Sub envelope: ${
          err instanceof Error ? err.message : 'unknown'
        }`,
      );
      return null;
    }
  }
}

// --- Webhook payload types ---

export interface GoogleRtdnEnvelope {
  message?: { data?: string; messageId?: string };
  subscription?: string;
}

interface GoogleDeveloperNotification {
  version?: string;
  packageName?: string;
  subscriptionNotification?: {
    notificationType: number;
    purchaseToken: string;
    subscriptionId: string;
  };
}
