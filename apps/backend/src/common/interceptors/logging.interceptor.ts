import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

/**
 * Structured request/response logging.
 *
 * Logs method, path, status and latency for every HTTP request. Deliberately
 * does NOT log request bodies (which may contain passwords, tokens or
 * receipts).
 */
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest();
    const { method, originalUrl } = req;
    const start = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const res = http.getResponse();
          const ms = Date.now() - start;
          this.logger.log(`${method} ${originalUrl} ${res.statusCode} ${ms}ms`);
        },
        error: (err) => {
          const ms = Date.now() - start;
          const status = err?.status ?? 500;
          this.logger.warn(`${method} ${originalUrl} ${status} ${ms}ms`);
        },
      }),
    );
  }
}
