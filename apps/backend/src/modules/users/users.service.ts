import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';
import { CacheService } from '../../common/cache/cache.service';
import { User } from './user.entity';
import { UpdateUserDto } from './dto/update-user.dto';

/** Public, serializable view of a user (never includes passwordHash). */
export interface UserProfile {
  id: string;
  email: string;
  authProvider: string;
  displayName: string | null;
  avatarUrl: string | null;
  emailVerified: boolean;
  role: string;
  timezone: string;
  locale: string;
  isPremium: boolean;
  premiumUntil: string | null;
  status: string;
  createdAt: string;
  updatedAt: string;
}

interface CreateEmailUserParams {
  email: string;
  passwordHash: string;
  displayName: string;
}

const PROFILE_CACHE_TTL_SECONDS = 60 * 15; // 15 minutes
const profileCacheKey = (userId: string) => `user:profile:${userId}`;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    private readonly cache: CacheService,
  ) {}

  /**
   * Create a local (email) account. The caller (AuthService) is responsible for
   * hashing the password; we only persist the hash.
   * Relies on the unique citext email constraint for race-safe uniqueness.
   */
  async createEmailUser(params: CreateEmailUserParams): Promise<User> {
    const user = this.usersRepo.create({
      email: params.email,
      passwordHash: params.passwordHash,
      displayName: params.displayName,
      authProvider: 'email',
    });

    try {
      return await this.usersRepo.save(user);
    } catch (err) {
      if (this.isUniqueViolation(err)) {
        throw new ConflictException('Email is already registered');
      }
      throw err;
    }
  }

  /**
   * Find a user by email including the password hash (which is `select:false` on
   * the entity). Used only by the login flow.
   */
  async findByEmailWithPassword(email: string): Promise<User | null> {
    return this.usersRepo
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.email = :email', { email })
      .andWhere('user.deletedAt IS NULL')
      .getOne();
  }

  /** Load the full entity by id, or null. */
  async findById(id: string): Promise<User | null> {
    return this.usersRepo.findOne({ where: { id } });
  }

  /** Load the full entity by id or throw 404. */
  async getByIdOrThrow(id: string): Promise<User> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  /**
   * Return the cacheable public profile for a user.
   * Reads from Redis first; on miss loads from Postgres and back-fills the cache.
   */
  async getProfile(userId: string): Promise<UserProfile> {
    const key = profileCacheKey(userId);

    const cached = await this.cache.get<UserProfile>(key);
    if (cached) {
      return cached;
    }

    const user = await this.getByIdOrThrow(userId);
    const profile = this.toProfile(user);
    await this.cache.set(key, profile, PROFILE_CACHE_TTL_SECONDS);
    return profile;
  }

  /**
   * Apply a partial profile update, persist it, and invalidate the cached
   * profile so the next read reflects the change.
   */
  async updateProfile(userId: string, dto: UpdateUserDto): Promise<UserProfile> {
    const user = await this.getByIdOrThrow(userId);

    if (dto.displayName !== undefined) user.displayName = dto.displayName;
    if (dto.timezone !== undefined) user.timezone = dto.timezone;
    if (dto.locale !== undefined) user.locale = dto.locale;

    const saved = await this.usersRepo.save(user);

    // Invalidate then warm the cache with the fresh profile.
    const profile = this.toProfile(saved);
    await this.cache.set(profileCacheKey(userId), profile, PROFILE_CACHE_TTL_SECONDS);
    return profile;
  }

  /** Explicitly drop a user's cached profile (e.g. on premium/role change). */
  async invalidateProfileCache(userId: string): Promise<void> {
    await this.cache.del(profileCacheKey(userId));
  }

  /** Map an entity to its safe public projection. */
  toProfile(user: User): UserProfile {
    return {
      id: user.id,
      email: user.email,
      authProvider: user.authProvider,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      emailVerified: user.emailVerified,
      role: user.role,
      timezone: user.timezone,
      locale: user.locale,
      isPremium: user.isPremium,
      premiumUntil: user.premiumUntil ? user.premiumUntil.toISOString() : null,
      status: user.status,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
    };
  }

  /** Detect a Postgres unique-violation (SQLSTATE 23505) wrapped by TypeORM. */
  private isUniqueViolation(err: unknown): boolean {
    return (
      err instanceof QueryFailedError &&
      (err as QueryFailedError & { code?: string }).code === '23505'
    );
  }
}
