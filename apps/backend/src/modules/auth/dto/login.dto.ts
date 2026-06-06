import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

/** POST /auth/login body. */
export class LoginDto {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'A valid email is required' })
  @MaxLength(254)
  email: string;

  // Don't expose the password policy on login to avoid leaking it to attackers;
  // just bound the length to prevent abuse.
  @IsString()
  @MinLength(1)
  @MaxLength(72)
  password: string;
}
