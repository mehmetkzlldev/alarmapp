import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

/**
 * Reusable pagination query parameters.
 *
 * `@Type(() => Number)` is required because query strings arrive as strings;
 * combined with the global `transform: true` ValidationPipe it coerces them to
 * numbers before validation.
 */
export class PaginationDto {
  @ApiPropertyOptional({
    description: '1-based page number',
    minimum: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page = 1;

  @ApiPropertyOptional({
    description: 'Items per page',
    minimum: 1,
    maximum: 100,
    default: 20,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit = 20;

  /** Computed offset for repository `skip`. */
  get skip(): number {
    return (this.page - 1) * this.limit;
  }
}

/** Standard paginated response wrapper. */
export class PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;

  constructor(items: T[], total: number, page: number, limit: number) {
    this.items = items;
    this.total = total;
    this.page = page;
    this.limit = limit;
    this.totalPages = Math.ceil(total / limit) || 1;
  }
}
