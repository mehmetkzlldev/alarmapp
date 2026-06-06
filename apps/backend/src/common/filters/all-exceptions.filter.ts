import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { QueryFailedError } from 'typeorm';

/**
 * Standardized error envelope matching the API contract:
 *   { statusCode, message, error, path, timestamp }
 */
interface ErrorResponseBody {
  statusCode: number;
  message: string | string[];
  error: string;
  path: string;
  timestamp: string;
}

/**
 * Global exception filter.
 *
 * Translates every thrown error into the contract's error shape. Handles:
 *   - HttpException (validation errors, guards, explicit throws)
 *   - TypeORM QueryFailedError (e.g. unique-violation -> 409)
 *   - Unknown errors -> 500 (details hidden from the client)
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exception');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const { status, message, error } = this.resolve(exception);

    const body: ErrorResponseBody = {
      statusCode: status,
      message,
      error,
      path: request.url,
      timestamp: new Date().toISOString(),
    };

    // Log server errors with stack; client errors at a quieter level.
    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        `${request.method} ${request.url} -> ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    } else {
      this.logger.warn(`${request.method} ${request.url} -> ${status}`);
    }

    response.status(status).json(body);
  }

  private resolve(exception: unknown): {
    status: number;
    message: string | string[];
    error: string;
  } {
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const res = exception.getResponse();
      // Nest's ValidationPipe returns { message: string[], error, statusCode }.
      if (typeof res === 'object' && res !== null) {
        const r = res as Record<string, unknown>;
        return {
          status,
          message: (r.message as string | string[]) ?? exception.message,
          error: (r.error as string) ?? HttpStatus[status] ?? 'Error',
        };
      }
      return {
        status,
        message: exception.message,
        error: HttpStatus[status] ?? 'Error',
      };
    }

    // Map common DB integrity errors to friendly statuses.
    if (exception instanceof QueryFailedError) {
      const driverCode = (exception as unknown as { code?: string }).code;
      if (driverCode === '23505') {
        return {
          status: HttpStatus.CONFLICT,
          message: 'Resource already exists',
          error: 'Conflict',
        };
      }
      if (driverCode === '23503') {
        return {
          status: HttpStatus.BAD_REQUEST,
          message: 'Related resource not found',
          error: 'Bad Request',
        };
      }
    }

    // Unknown/unhandled — never leak internals to the client.
    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      message: 'Internal server error',
      error: 'Internal Server Error',
    };
  }
}
