import { SetMetadata } from '@nestjs/common';
import { REQUIRES_PREMIUM_KEY } from '../constants';

/**
 * Marks a route as requiring an active subscription. Enforced by `PremiumGuard`.
 * Used on GET /ai-missions/today and GET /sleep/statistics.
 */
export const Premium = () => SetMetadata(REQUIRES_PREMIUM_KEY, true);
