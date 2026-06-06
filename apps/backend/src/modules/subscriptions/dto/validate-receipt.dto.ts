import { IsIn, IsNotEmpty, IsString, MaxLength } from 'class-validator';

/**
 * Body for POST /subscriptions/validate.
 *
 * `receipt` is the store-provided token:
 *   - play_store: the purchaseToken from Google Play Billing
 *   - app_store:  the base64 unified receipt OR a StoreKit2 JWS transaction
 * We never trust the client beyond using these to call the store's own API.
 */
export class ValidateReceiptDto {
  @IsIn(['app_store', 'play_store'])
  store: 'app_store' | 'play_store';

  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  productId: string;

  @IsString()
  @IsNotEmpty()
  // Receipts can be large (Apple unified receipts); cap defensively.
  @MaxLength(20000)
  receipt: string;
}
