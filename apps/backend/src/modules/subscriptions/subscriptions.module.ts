import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import { Subscription } from './subscription.entity';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';

/**
 * Registers the Subscription + User entities so the service can sync premium
 * flags. RedisService is provided globally by the RedisModule; ConfigModule
 * supplies store credentials.
 */
@Module({
  imports: [
    TypeOrmModule.forFeature([Subscription, User]),
    ConfigModule,
  ],
  controllers: [SubscriptionsController],
  providers: [SubscriptionsService],
  exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
