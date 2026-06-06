/**
 * Minimal, dependency-free circuit breaker.
 *
 * States:
 *   CLOSED    -> calls flow through; failures are counted.
 *   OPEN      -> calls are rejected immediately for `cooldownMs`.
 *   HALF_OPEN -> a single trial call is allowed; success closes the breaker,
 *                failure re-opens it.
 *
 * This protects us (and the Gemini quota) from hammering an upstream that is
 * already failing, and gives callers a fast, predictable error instead of a
 * pile-up of slow timeouts.
 */

export type CircuitState = 'CLOSED' | 'OPEN' | 'HALF_OPEN';

export interface CircuitBreakerOptions {
  /** Consecutive failures before the breaker trips OPEN. */
  failureThreshold: number;
  /** How long to stay OPEN before allowing a trial (HALF_OPEN) call, in ms. */
  cooldownMs: number;
}

export class CircuitOpenError extends Error {
  constructor(retryAfterMs: number) {
    super(
      `Circuit breaker is OPEN; upstream temporarily unavailable. Retry in ~${Math.ceil(
        retryAfterMs / 1000,
      )}s.`,
    );
    this.name = 'CircuitOpenError';
  }
}

export class CircuitBreaker {
  private state: CircuitState = 'CLOSED';
  private failureCount = 0;
  private openedAt = 0;

  constructor(private readonly options: CircuitBreakerOptions) {}

  getState(): CircuitState {
    return this.state;
  }

  /**
   * Run `fn` under breaker protection. Throws CircuitOpenError without invoking
   * `fn` when the circuit is OPEN and still cooling down.
   */
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      const elapsed = Date.now() - this.openedAt;
      if (elapsed < this.options.cooldownMs) {
        throw new CircuitOpenError(this.options.cooldownMs - elapsed);
      }
      // Cooldown elapsed: allow one trial call.
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (err) {
      this.onFailure();
      throw err;
    }
  }

  private onSuccess(): void {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  private onFailure(): void {
    this.failureCount += 1;
    // A failure during a HALF_OPEN trial immediately re-opens the breaker.
    if (
      this.state === 'HALF_OPEN' ||
      this.failureCount >= this.options.failureThreshold
    ) {
      this.state = 'OPEN';
      this.openedAt = Date.now();
    }
  }
}
