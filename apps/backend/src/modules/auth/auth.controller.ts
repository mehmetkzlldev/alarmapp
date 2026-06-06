import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Ip,
  Post,
  Req,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { Public } from '../../common/decorators';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import type { RequestContext } from './tokens.service';

/**
 * Auth endpoints under /api/v1/auth (global prefix + versioning applied at the
 * app level). Auth routes are public (no JwtAuthGuard) but rate-limited more
 * aggressively than the default to blunt credential-stuffing.
 */
@Public() // all /auth routes bypass the global JwtAuthGuard (deny-by-default)
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /** POST /auth/register -> { user, accessToken, refreshToken } */
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  register(@Body() dto: RegisterDto, @Req() req: Request, @Ip() ip: string) {
    return this.authService.register(dto, this.ctx(req, ip));
  }

  /** POST /auth/login -> { user, accessToken, refreshToken } */
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto, @Req() req: Request, @Ip() ip: string) {
    return this.authService.login(dto, this.ctx(req, ip));
  }

  /** POST /auth/refresh -> { accessToken, refreshToken } (rotating) */
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto, @Req() req: Request, @Ip() ip: string) {
    return this.authService.refresh(dto.refreshToken, this.ctx(req, ip));
  }

  /** POST /auth/logout -> 204 No Content */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshDto): Promise<void> {
    await this.authService.logout(dto.refreshToken);
  }

  /** Extract request metadata persisted alongside refresh tokens. */
  private ctx(req: Request, ip: string): RequestContext {
    return {
      userAgent: req.headers['user-agent'] ?? null,
      ip: ip ?? req.ip ?? null,
    };
  }
}
