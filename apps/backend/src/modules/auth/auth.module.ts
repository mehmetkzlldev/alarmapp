import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RefreshToken } from '../users/refresh-token.entity';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { TokensService } from './tokens.service';
import { JwtStrategy } from './jwt.strategy';

/**
 * Auth feature module. Wires the passport JWT strategy and the token services.
 *
 * - JwtModule is registered without a global secret on purpose: TokensService
 *   passes the access/refresh secret per-sign so the two key spaces stay
 *   separate. Secrets are resolved from ConfigService (env), never hardcoded.
 * - PassportModule provides the 'jwt' strategy used by the shared JwtAuthGuard.
 */
@Module({
  imports: [
    UsersModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({}),
    TypeOrmModule.forFeature([RefreshToken]),
  ],
  controllers: [AuthController],
  providers: [AuthService, TokensService, JwtStrategy],
  exports: [AuthService, TokensService, JwtStrategy, PassportModule],
})
export class AuthModule {}
