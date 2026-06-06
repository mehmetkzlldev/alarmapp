import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
  StreamableFile,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * Envelope returned for successful responses.
 *
 * The API contract uses JSON bodies that are the resource itself (e.g. an
 * `Alarm`), so by default we return payloads as-is. This interceptor is kept
 * intentionally minimal: it only wraps `null`/`undefined` bodies into a stable
 * shape and leaves real payloads untouched, preserving the documented
 * response schemas while guaranteeing JSON is always emitted.
 */
@Injectable()
export class TransformResponseInterceptor<T>
  implements NestInterceptor<T, T | { success: true }>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<T | { success: true }> {
    const statusCode: number = context
      .switchToHttp()
      .getResponse().statusCode;

    return next.handle().pipe(
      map((data) => {
        // Don't touch binary/stream responses.
        if (data instanceof StreamableFile) {
          return data;
        }
        // 204 No Content MUST have an empty body — never wrap it. This covers
        // the contract's logout / delete endpoints.
        if (statusCode === 204) {
          return data;
        }
        // Other handlers that return nothing get a stable success marker so the
        // client always receives valid JSON.
        if (data === undefined || data === null) {
          return { success: true };
        }
        return data;
      }),
    );
  }
}
