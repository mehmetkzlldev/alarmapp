import {
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { NotificationLog } from './notification-log.entity';
import { NotificationsService } from './notifications.service';

/**
 * User-facing notification inbox.
 * Base path: /api/v1/notifications (global prefix applied in main.ts).
 */
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  /** GET /notifications — list the caller's notifications, newest first. */
  @Get()
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
  ): Promise<NotificationLog[]> {
    return this.notifications.listForUser(user.id, limit, offset);
  }

  /** PATCH /notifications/:id/read — mark a single notification as read. */
  @Patch(':id/read')
  markRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<NotificationLog> {
    return this.notifications.markRead(user.id, id);
  }
}
