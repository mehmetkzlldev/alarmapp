import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/auth/jwt-auth.guard';
import { CurrentUser } from '../../common/auth/current-user.decorator';
import type { AuthenticatedUser } from '../../common/auth/jwt-payload.interface';
import { UsersService, UserProfile } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';

/**
 * /api/v1/users — the authenticated user's own profile.
 *
 * Auth is enforced by the per-controller JwtAuthGuard (the app has no global
 * guard); every route here requires a valid access token.
 */
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /** GET /users/me -> User (served from Redis cache when warm) */
  @Get('me')
  getMe(@CurrentUser() user: AuthenticatedUser): Promise<UserProfile> {
    return this.usersService.getProfile(user.id);
  }

  /** PATCH /users/me { displayName?, timezone?, locale? } -> User */
  @Patch('me')
  updateMe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateUserDto,
  ): Promise<UserProfile> {
    return this.usersService.updateProfile(user.id, dto);
  }
}
