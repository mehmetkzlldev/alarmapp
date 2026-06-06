import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { Public } from '../../common/decorators/public.decorator';
import { ValidateReceiptDto } from './dto/validate-receipt.dto';
import { Plan } from './plans.constant';
import { Subscription } from './subscription.entity';
import {
  GoogleRtdnEnvelope,
  SubscriptionsService,
} from './subscriptions.service';

/**
 * Base path: /api/v1/subscriptions.
 *
 * The two webhook endpoints are @Public (no JWT) because they are called by
 * Google Pub/Sub and Apple's notification service, not the app. They remain
 * protected by store-side signature verification inside the service and should
 * additionally be IP/secret-gated at the edge.
 */
@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  constructor(private readonly subscriptions: SubscriptionsService) {}

  /** GET /subscriptions/me */
  @Get('me')
  me(@CurrentUser() user: AuthenticatedUser): Promise<Subscription> {
    return this.subscriptions.getForUser(user.id);
  }

  /** GET /subscriptions/plans */
  @Get('plans')
  plans(): Plan[] {
    return this.subscriptions.getPlans();
  }

  /** POST /subscriptions/validate — server-side receipt validation. */
  @Post('validate')
  @HttpCode(200)
  validate(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ValidateReceiptDto,
  ): Promise<Subscription> {
    return this.subscriptions.validateReceipt(user.id, dto);
  }

  /**
   * POST /subscriptions/webhook/google — Google Play RTDN (Pub/Sub push).
   * Returns 204 quickly so Pub/Sub does not redeliver on slow processing;
   * failures are logged internally.
   */
  @Post('webhook/google')
  @Public()
  @HttpCode(204)
  async googleWebhook(@Body() body: GoogleRtdnEnvelope): Promise<void> {
    await this.subscriptions.handleGoogleNotification(body);
  }

  /**
   * POST /subscriptions/webhook/apple — App Store Server Notifications V2.
   * Body: { signedPayload: <JWS> }.
   */
  @Post('webhook/apple')
  @Public()
  @HttpCode(204)
  async appleWebhook(
    @Body() body: { signedPayload: string },
  ): Promise<void> {
    if (body?.signedPayload) {
      await this.subscriptions.handleAppleNotification(body.signedPayload);
    }
  }
}
