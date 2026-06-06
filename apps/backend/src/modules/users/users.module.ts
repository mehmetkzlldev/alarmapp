import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CacheModule } from '../../common/cache/cache.module';
import { User } from './user.entity';
import { RefreshToken } from './refresh-token.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';

/**
 * Users feature module. Owns the `users` and `refresh_tokens` entities (the
 * latter is registered here because it's defined under users/; AuthModule
 * separately registers the same entity for its repository injection).
 *
 * UsersService is exported so AuthModule can create/look up users.
 * CacheService is provided globally by CacheModule.
 */
@Module({
  imports: [TypeOrmModule.forFeature([User, RefreshToken]), CacheModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService, TypeOrmModule],
})
export class UsersModule {}
