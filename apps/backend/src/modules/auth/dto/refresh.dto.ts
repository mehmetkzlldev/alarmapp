import { IsJWT, IsString } from 'class-validator';

/**
 * Body shared by POST /auth/refresh and POST /auth/logout.
 * The refresh token is a signed JWT (its `jti` maps to a refresh_tokens row).
 */
export class RefreshDto {
  @IsString()
  @IsJWT({ message: 'refreshToken must be a valid token' })
  refreshToken: string;
}
