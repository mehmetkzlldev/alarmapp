import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { GeminiService } from './gemini.service';

/**
 * Provides the Gemini client wrapper application-wide.
 *
 * Marked @Global so feature modules (object-detection, ai-mission) can inject
 * GeminiService without re-importing this module everywhere.
 */
@Global()
@Module({
  imports: [ConfigModule],
  providers: [GeminiService],
  exports: [GeminiService],
})
export class GeminiModule {}
