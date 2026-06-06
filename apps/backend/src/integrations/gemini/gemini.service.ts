import {
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

import {
  AnalyzeImageOptions,
  GeminiResult,
  GeminiUsage,
  GenerateJsonOptions,
  ImageSource,
} from './gemini.types';
import {
  CircuitBreaker,
  CircuitOpenError,
} from './circuit-breaker';

const DEFAULT_MODEL = 'gemini-2.5-flash';
const DEFAULT_TIMEOUT_MS = 20_000;
const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_BACKOFF_BASE_MS = 400;
const DEFAULT_BACKOFF_CAP_MS = 8_000;

/**
 * Robust wrapper around the latest Google Gen AI SDK (`@google/genai`).
 *
 * Responsibilities:
 *  - Read the API key from the environment ONLY (never from client/Flutter).
 *  - Force structured JSON output via responseMimeType + responseSchema.
 *  - Apply a per-call timeout, exponential backoff with jitter, and a circuit
 *    breaker so a flaky upstream cannot cascade into the rest of the API.
 *  - Emit structured usage logs for cost/observability.
 */
@Injectable()
export class GeminiService implements OnModuleInit {
  private readonly logger = new Logger(GeminiService.name);

  private client!: GoogleGenAI;
  private readonly defaultModel: string;
  private readonly maxRetries: number;
  private readonly breaker: CircuitBreaker;

  constructor(private readonly config: ConfigService) {
    this.defaultModel =
      this.config.get<string>('GEMINI_MODEL') ?? DEFAULT_MODEL;
    this.maxRetries =
      this.config.get<number>('GEMINI_MAX_RETRIES') ?? DEFAULT_MAX_RETRIES;
    this.breaker = new CircuitBreaker({
      failureThreshold:
        this.config.get<number>('GEMINI_BREAKER_THRESHOLD') ?? 5,
      cooldownMs:
        this.config.get<number>('GEMINI_BREAKER_COOLDOWN_MS') ?? 30_000,
    });
  }

  onModuleInit(): void {
    // SECURITY: the API key is read from the environment exclusively. It must
    // never be shipped to the Flutter client or accepted from request bodies.
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      // Fail fast at boot rather than at first request — misconfiguration is
      // an operator error, not a runtime condition we should swallow.
      throw new Error(
        'GEMINI_API_KEY is not set. Refusing to start the Gemini integration.',
      );
    }
    this.client = new GoogleGenAI({ apiKey });
    this.logger.log(
      `Gemini client initialized (model=${this.defaultModel}, maxRetries=${this.maxRetries})`,
    );
  }

  /**
   * Generate a strictly-typed JSON object from a text prompt.
   *
   * @param prompt  The user/content prompt.
   * @param schema  A Gemini responseSchema (OpenAPI-subset JSON schema object).
   */
  async generateJson<T>(
    prompt: string,
    schema: Record<string, unknown>,
    options: GenerateJsonOptions = {},
  ): Promise<GeminiResult<T>> {
    const model = options.model ?? this.defaultModel;
    return this.run<T>(model, options.timeoutMs ?? DEFAULT_TIMEOUT_MS, () =>
      this.client.models.generateContent({
        model,
        contents: prompt,
        config: {
          responseMimeType: 'application/json',
          responseSchema: schema,
          temperature: options.temperature ?? 0.4,
          maxOutputTokens: options.maxOutputTokens ?? 1024,
          ...(options.systemInstruction
            ? { systemInstruction: options.systemInstruction }
            : {}),
        },
      }),
    );
  }

  /**
   * Multimodal analysis: send an image plus a prompt, receive structured JSON.
   * Used by object detection (Gemini Vision).
   */
  async analyzeImage<T>(
    options: AnalyzeImageOptions,
  ): Promise<GeminiResult<T>> {
    const model = options.model ?? this.defaultModel;
    const imagePart = await this.buildImagePart(options.image);

    return this.run<T>(model, options.timeoutMs ?? DEFAULT_TIMEOUT_MS, () =>
      this.client.models.generateContent({
        model,
        contents: [
          {
            role: 'user',
            parts: [imagePart, { text: options.prompt }],
          },
        ],
        config: {
          responseMimeType: 'application/json',
          responseSchema: options.schema as Record<string, unknown>,
          temperature: options.temperature ?? 0.1,
          ...(options.systemInstruction
            ? { systemInstruction: options.systemInstruction }
            : {}),
        },
      }),
    );
  }

  /**
   * Convert our ImageSource into a Gemini inline-data / file part.
   * We prefer inline bytes (private S3 stream) over URLs so we never hand a
   * publicly-resolvable URL to the model provider.
   */
  private async buildImagePart(image: ImageSource) {
    if (image.bytes) {
      const mimeType = image.mimeType ?? 'image/jpeg';
      const base64 = Buffer.from(image.bytes).toString('base64');
      return { inlineData: { mimeType, data: base64 } };
    }
    if (image.url) {
      // Fall back to fetching the URL ourselves so we control the timeout and
      // can still send inline bytes (Gemini's HTTP fetch has no SLA we control).
      const bytes = await this.fetchImageBytes(image.url);
      return {
        inlineData: {
          mimeType: image.mimeType ?? this.guessMimeFromUrl(image.url),
          data: Buffer.from(bytes).toString('base64'),
        },
      };
    }
    throw new Error('analyzeImage requires either image.bytes or image.url');
  }

  private async fetchImageBytes(url: string): Promise<Buffer> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);
    try {
      const res = await fetch(url, { signal: controller.signal });
      if (!res.ok) {
        throw new Error(`Failed to fetch image (${res.status})`);
      }
      const arrayBuffer = await res.arrayBuffer();
      return Buffer.from(arrayBuffer);
    } finally {
      clearTimeout(timer);
    }
  }

  private guessMimeFromUrl(url: string): string {
    const lower = url.split('?')[0].toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  /**
   * Core execution path: circuit breaker -> retry loop -> timeout -> parse.
   */
  private async run<T>(
    model: string,
    timeoutMs: number,
    call: () => Promise<unknown>,
  ): Promise<GeminiResult<T>> {
    const startedAt = Date.now();

    try {
      const response = await this.breaker.execute(() =>
        this.withRetries(() => this.withTimeout(call(), timeoutMs)),
      );

      const latencyMs = Date.now() - startedAt;
      const parsed = this.parseResponse<T>(response);
      const usage = this.extractUsage(response);
      const requestId = this.extractRequestId(response);

      this.logger.log(
        `Gemini OK model=${model} latencyMs=${latencyMs} ` +
          `promptTokens=${usage.promptTokens} ` +
          `candidatesTokens=${usage.candidatesTokens} ` +
          `totalTokens=${usage.totalTokens} requestId=${requestId ?? 'n/a'}`,
      );

      return { data: parsed, usage, requestId, model, latencyMs };
    } catch (err) {
      const latencyMs = Date.now() - startedAt;
      if (err instanceof CircuitOpenError) {
        this.logger.warn(`Gemini circuit OPEN model=${model}: ${err.message}`);
        throw new ServiceUnavailableException(
          'AI service is temporarily unavailable. Please try again shortly.',
        );
      }
      this.logger.error(
        `Gemini FAILED model=${model} latencyMs=${latencyMs}: ${
          (err as Error).message
        }`,
      );
      throw new ServiceUnavailableException(
        'AI service request failed. Please try again.',
      );
    }
  }

  /** Exponential backoff with full jitter, retrying only on transient errors. */
  private async withRetries<T>(fn: () => Promise<T>): Promise<T> {
    let lastErr: unknown;
    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        return await fn();
      } catch (err) {
        lastErr = err;
        if (!this.isRetryable(err) || attempt === this.maxRetries) {
          break;
        }
        const backoff = Math.min(
          DEFAULT_BACKOFF_CAP_MS,
          DEFAULT_BACKOFF_BASE_MS * 2 ** attempt,
        );
        const jittered = Math.floor(Math.random() * backoff);
        this.logger.warn(
          `Gemini transient error (attempt ${attempt + 1}/${
            this.maxRetries + 1
          }), retrying in ${jittered}ms: ${(err as Error).message}`,
        );
        await this.delay(jittered);
      }
    }
    throw lastErr;
  }

  /** Reject if `promise` does not settle within `timeoutMs`. */
  private withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(`Gemini request timed out after ${timeoutMs}ms`));
      }, timeoutMs);
      promise.then(
        (value) => {
          clearTimeout(timer);
          resolve(value);
        },
        (err) => {
          clearTimeout(timer);
          reject(err);
        },
      );
    });
  }

  /**
   * Transient: timeouts, rate limits (429), and 5xx upstream errors are worth
   * retrying. Validation / auth errors (4xx other than 429) are not.
   */
  private isRetryable(err: unknown): boolean {
    const message = (err as Error)?.message?.toLowerCase() ?? '';
    if (message.includes('timed out')) return true;
    // The SDK surfaces an HTTP-ish status on the error object in many cases.
    const status = (err as { status?: number; code?: number })?.status ??
      (err as { status?: number; code?: number })?.code;
    if (typeof status === 'number') {
      if (status === 429) return true;
      if (status >= 500 && status <= 599) return true;
      return false;
    }
    // Network-level failures without a status are treated as transient.
    return (
      message.includes('network') ||
      message.includes('fetch failed') ||
      message.includes('econnreset') ||
      message.includes('socket hang up')
    );
  }

  /**
   * Parse the model's JSON output. With responseMimeType=application/json the
   * SDK returns a JSON string in `.text`; some SDK versions also expose
   * `.parsed`. We defensively support both and validate it is an object.
   */
  private parseResponse<T>(response: unknown): T {
    const r = response as { text?: string; parsed?: unknown };
    if (r.parsed && typeof r.parsed === 'object') {
      return r.parsed as T;
    }
    const text = r.text;
    if (!text || typeof text !== 'string') {
      throw new Error('Gemini returned an empty or non-text response');
    }
    try {
      return JSON.parse(text) as T;
    } catch {
      throw new Error(
        'Gemini returned malformed JSON despite responseMimeType=application/json',
      );
    }
  }

  private extractUsage(response: unknown): GeminiUsage {
    const meta = (response as { usageMetadata?: Record<string, number> })
      ?.usageMetadata;
    return {
      promptTokens: meta?.promptTokenCount ?? 0,
      candidatesTokens: meta?.candidatesTokenCount ?? 0,
      totalTokens: meta?.totalTokenCount ?? 0,
    };
  }

  private extractRequestId(response: unknown): string | null {
    const r = response as { responseId?: string };
    return r?.responseId ?? null;
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
