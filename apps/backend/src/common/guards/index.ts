// JwtAuthGuard and PremiumGuard are the canonical implementations under
// `src/common/auth/`. This barrel exposes only the role-based guard that lives
// here to avoid duplicate class definitions.
export * from './roles.guard';
