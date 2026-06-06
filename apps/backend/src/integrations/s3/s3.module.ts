import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { StorageService } from './s3.service';

/**
 * Provides the StorageService (private S3 bucket access) application-wide.
 */
@Global()
@Module({
  imports: [ConfigModule],
  providers: [StorageService],
  exports: [StorageService],
})
export class S3Module {}
