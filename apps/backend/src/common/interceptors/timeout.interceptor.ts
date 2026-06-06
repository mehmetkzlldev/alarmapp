import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
  RequestTimeoutException,
} from '@nestjs/common';
import { Observable, throwError, TimeoutError } from 'rxjs';
import { catchError, timeout } from 'rxjs/operators';

/**
 * Fails any request that exceeds a wall-clock budget, preventing slow upstream
 * calls (Gemini, S3, FCM) from holding connections open indefinitely.
 *
 * 30s is generous enough for image-based Gemini object detection while still
 * bounding worst-case latency.
 */
@Injectable()
export class TimeoutInterceptor implements NestInterceptor {
  private static readonly DEFAULT_TIMEOUT_MS = 30_000;

  constructor(
    private readonly timeoutMs: number = TimeoutInterceptor.DEFAULT_TIMEOUT_MS,
  ) {}

  intercept(_context: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(
      timeout(this.timeoutMs),
      catchError((err) => {
        if (err instanceof TimeoutError) {
          return throwError(
            () => new RequestTimeoutException('Request timed out'),
          );
        }
        return throwError(() => err);
      }),
    );
  }
}
