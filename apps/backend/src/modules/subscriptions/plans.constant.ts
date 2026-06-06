import { SubscriptionPlan } from './subscription.entity';

/**
 * Plan catalog returned by GET /subscriptions/plans and used to map store
 * product ids -> internal plan codes during receipt validation.
 *
 * Store product ids are configurable via env so the same build works across
 * staging/prod store configurations without code changes. Defaults match the
 * conventional Alarmy-style naming.
 */
export interface Plan {
  /** Internal plan code (matches subscriptions.plan). */
  code: SubscriptionPlan;
  name: string;
  description: string;
  /** Billing interval in days (informational; not used for entitlement math). */
  intervalDays: number;
  priceUsd: number;
  /** Store product identifiers keyed by store. */
  productIds: {
    app_store: string;
    play_store: string;
  };
}

/**
 * Read a product id from env with a sensible default. We do this at module load
 * so the catalog is static, but values still come from configuration.
 */
function pid(envKey: string, fallback: string): string {
  return process.env[envKey] || fallback;
}

export const PLANS: Plan[] = [
  {
    code: 'free',
    name: 'Free',
    description: 'Basic alarms with limited missions and no AI features.',
    intervalDays: 0,
    priceUsd: 0,
    productIds: { app_store: '', play_store: '' },
  },
  {
    code: 'premium_monthly',
    name: 'Premium (Monthly)',
    description:
      'Unlimited alarms, AI missions, object-detection, and sleep statistics.',
    intervalDays: 30,
    priceUsd: 4.99,
    productIds: {
      app_store: pid('IAP_APPLE_MONTHLY_ID', 'com.alarmy.premium.monthly'),
      play_store: pid('IAP_GOOGLE_MONTHLY_ID', 'premium_monthly'),
    },
  },
  {
    code: 'premium_yearly',
    name: 'Premium (Yearly)',
    description:
      'Everything in Premium Monthly at a discount, billed annually.',
    intervalDays: 365,
    priceUsd: 39.99,
    productIds: {
      app_store: pid('IAP_APPLE_YEARLY_ID', 'com.alarmy.premium.yearly'),
      play_store: pid('IAP_GOOGLE_YEARLY_ID', 'premium_yearly'),
    },
  },
];

/** All product ids that map to a premium (paid) plan. */
export const PREMIUM_PLAN_CODES: SubscriptionPlan[] = [
  'premium_monthly',
  'premium_yearly',
];

/**
 * Resolve an internal plan code from a store + product id.
 * Returns null if the product id is unknown (caller should reject the receipt).
 */
export function resolvePlanByProductId(
  store: 'app_store' | 'play_store',
  productId: string,
): SubscriptionPlan | null {
  const match = PLANS.find(
    (p) => p.productIds[store] && p.productIds[store] === productId,
  );
  return match ? match.code : null;
}
