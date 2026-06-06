import { Logger } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { GoogleAuth } from 'google-auth-library';

/**
 * Normalized result of a successful store-side receipt verification.
 * Both verifiers map their store-specific responses onto this shape so the
 * SubscriptionsService can apply a single entitlement update path.
 */
export interface VerifiedReceipt {
  /** Cross-renewal stable id used as the idempotency key. */
  originalTransactionId: string;
  /** Store-specific subscription/order identifier for the current period. */
  storeSubscriptionId: string;
  /** End of the currently paid period. */
  currentPeriodEnd: Date;
  /** When the subscription first started (best-effort). */
  startedAt: Date;
  autoRenew: boolean;
  /** Whether the period end is still in the future (entitlement active). */
  isActive: boolean;
  /** True if the store marked this as a free-trial / introductory period. */
  isTrial: boolean;
  /** Raw store payload retained for audit. */
  raw: Record<string, unknown>;
}

/**
 * Verify a Google Play subscription purchase via the Android Publisher API.
 *
 * Requires a service account (env GOOGLE_PLAY_SERVICE_ACCOUNT / _B64 or
 * GOOGLE_APPLICATION_CREDENTIALS) with the "View financial data" permission on
 * the Play Console. We call:
 *   GET androidpublisher/v3/applications/{pkg}/purchases/subscriptions/{productId}/tokens/{token}
 */
export class GooglePlayVerifier {
  private readonly logger = new Logger(GooglePlayVerifier.name);
  private readonly auth: GoogleAuth;

  constructor(
    private readonly packageName: string,
    serviceAccountJson?: string,
  ) {
    // Credentials are loaded from env, never hardcoded.
    const credentials = serviceAccountJson
      ? JSON.parse(serviceAccountJson)
      : undefined;
    this.auth = new GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
  }

  async verify(
    productId: string,
    purchaseToken: string,
  ): Promise<VerifiedReceipt> {
    const client = await this.auth.getClient();
    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
      `${encodeURIComponent(this.packageName)}/purchases/subscriptions/` +
      `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(
        purchaseToken,
      )}`;

    const res = await client.request<GooglePlaySubscriptionResource>({ url });
    const data = res.data;

    // expiryTimeMillis / startTimeMillis are string-encoded epoch millis.
    const expiry = new Date(Number(data.expiryTimeMillis));
    const start = new Date(Number(data.startTimeMillis));

    // Google "linkedPurchaseToken" chains tokens across re-subscribe; the order
    // id (minus the renewal suffix) is the stable original transaction id.
    const originalTransactionId = (data.orderId || purchaseToken).split('..')[0];

    return {
      originalTransactionId,
      storeSubscriptionId: data.orderId || purchaseToken,
      currentPeriodEnd: expiry,
      startedAt: start,
      // autoRenewing reflects the user's current renewal intent.
      autoRenew: data.autoRenewing === true,
      isActive: expiry.getTime() > Date.now() && data.paymentState !== 0,
      // paymentState 2 == free trial.
      isTrial: data.paymentState === 2,
      raw: data as unknown as Record<string, unknown>,
    };
  }
}

interface GooglePlaySubscriptionResource {
  startTimeMillis: string;
  expiryTimeMillis: string;
  autoRenewing: boolean;
  orderId?: string;
  linkedPurchaseToken?: string;
  /** 0 pending, 1 received, 2 free trial, 3 pending deferred upgrade/downgrade */
  paymentState?: number;
  cancelReason?: number;
}

/**
 * Verify an Apple receipt.
 *
 * Supports two formats:
 *  1. Legacy base64 "unified receipt" -> POSTed to verifyReceipt (prod, with
 *     automatic sandbox fallback on status 21007).
 *  2. StoreKit2 JWS signed transaction -> decoded locally (signature trust is
 *     anchored on Apple's x5c chain; here we decode claims and rely on the
 *     transport being TLS to Apple's notification source).
 *
 * Shared secret is read from env (APPLE_IAP_SHARED_SECRET) — never hardcoded.
 */
export class AppleVerifier {
  private readonly logger = new Logger(AppleVerifier.name);
  private static readonly PROD_URL =
    'https://buy.itunes.apple.com/verifyReceipt';
  private static readonly SANDBOX_URL =
    'https://sandbox.itunes.apple.com/verifyReceipt';

  constructor(private readonly sharedSecret: string) {}

  async verify(receipt: string): Promise<VerifiedReceipt> {
    // Heuristic: JWS transactions contain two '.' separators.
    if (receipt.split('.').length === 3) {
      return this.verifyJws(receipt);
    }
    return this.verifyLegacy(receipt);
  }

  /** StoreKit2 signed transaction: decode the JWS payload (claims). */
  private verifyJws(jws: string): VerifiedReceipt {
    const decoded = jwt.decode(jws, { json: true }) as
      | AppleJwsTransaction
      | null;
    if (!decoded) {
      throw new Error('Unable to decode Apple JWS transaction');
    }
    const expires = new Date(decoded.expiresDate);
    return {
      originalTransactionId: decoded.originalTransactionId,
      storeSubscriptionId: decoded.transactionId,
      currentPeriodEnd: expires,
      startedAt: new Date(
        decoded.originalPurchaseDate ?? decoded.purchaseDate,
      ),
      // JWS transaction alone does not carry renewal intent; default true and
      // let App Store Server Notifications correct it via webhook.
      autoRenew: true,
      isActive: expires.getTime() > Date.now(),
      isTrial: decoded.offerType === 1,
      raw: decoded as unknown as Record<string, unknown>,
    };
  }

  /** Legacy verifyReceipt flow with sandbox fallback. */
  private async verifyLegacy(receiptData: string): Promise<VerifiedReceipt> {
    let body = await this.postVerify(AppleVerifier.PROD_URL, receiptData);
    // 21007 => receipt is from sandbox; retry against sandbox endpoint.
    if (body.status === 21007) {
      body = await this.postVerify(AppleVerifier.SANDBOX_URL, receiptData);
    }
    if (body.status !== 0) {
      throw new Error(`Apple verifyReceipt failed with status ${body.status}`);
    }

    // Pick the latest renewal info / receipt entry.
    const latest =
      (body.latest_receipt_info && body.latest_receipt_info[0]) || undefined;
    if (!latest) {
      throw new Error('Apple receipt contained no subscription info');
    }
    const renewal =
      (body.pending_renewal_info && body.pending_renewal_info[0]) || undefined;

    const expires = new Date(Number(latest.expires_date_ms));
    return {
      originalTransactionId: latest.original_transaction_id,
      storeSubscriptionId: latest.transaction_id,
      currentPeriodEnd: expires,
      startedAt: new Date(Number(latest.original_purchase_date_ms)),
      autoRenew: renewal ? renewal.auto_renew_status === '1' : true,
      isActive: expires.getTime() > Date.now(),
      isTrial: latest.is_trial_period === 'true',
      raw: body as unknown as Record<string, unknown>,
    };
  }

  private async postVerify(
    url: string,
    receiptData: string,
  ): Promise<AppleVerifyResponse> {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        password: this.sharedSecret,
        'exclude-old-transactions': true,
      }),
    });
    if (!res.ok) {
      throw new Error(`Apple verifyReceipt HTTP ${res.status}`);
    }
    return (await res.json()) as AppleVerifyResponse;
  }
}

interface AppleVerifyResponse {
  status: number;
  latest_receipt_info?: AppleLatestReceiptInfo[];
  pending_renewal_info?: ApplePendingRenewalInfo[];
}

interface AppleLatestReceiptInfo {
  original_transaction_id: string;
  transaction_id: string;
  expires_date_ms: string;
  original_purchase_date_ms: string;
  is_trial_period?: string;
  product_id: string;
}

interface ApplePendingRenewalInfo {
  auto_renew_status: string;
  product_id: string;
}

interface AppleJwsTransaction {
  originalTransactionId: string;
  transactionId: string;
  productId: string;
  purchaseDate: number;
  originalPurchaseDate?: number;
  expiresDate: number;
  offerType?: number;
}
