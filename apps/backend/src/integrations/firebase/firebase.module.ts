import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FirebaseService } from './firebase.service';

/**
 * Firebase is marked @Global so any feature module (notifications, auth, etc.)
 * can inject FirebaseService without re-importing this module.
 */
@Global()
@Module({
  imports: [ConfigModule],
  providers: [FirebaseService],
  exports: [FirebaseService],
})
export class FirebaseModule {}
