import {
  ArgumentMetadata,
  BadRequestException,
  Injectable,
  PipeTransform,
} from '@nestjs/common';

const UUID_V4 =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * Validates that a route param is a UUID before it reaches the service layer,
 * producing a clean 400 instead of a Postgres cast error. Nest also ships
 * `ParseUUIDPipe`; this variant emits a friendlier, field-aware message.
 */
@Injectable()
export class ParseUuidOrFailPipe implements PipeTransform<string, string> {
  transform(value: string, metadata: ArgumentMetadata): string {
    if (!value || !UUID_V4.test(value)) {
      throw new BadRequestException(
        `Invalid identifier for "${metadata.data ?? 'param'}"`,
      );
    }
    return value;
  }
}
