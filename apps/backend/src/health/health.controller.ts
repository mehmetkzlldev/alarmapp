import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../common/decorators';

/**
 * Liveness endpoint used by container/orchestrator healthchecks and the
 * Flutter client's connectivity probe.
 *
 * GET /api/v1/health -> { status: 'ok' }
 */
@ApiTags('health')
@Controller('health')
export class HealthController {
  @Public()
  @Get()
  @ApiOkResponse({
    schema: {
      type: 'object',
      properties: { status: { type: 'string', example: 'ok' } },
    },
  })
  check(): { status: 'ok' } {
    return { status: 'ok' };
  }
}
