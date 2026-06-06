/**
 * Shared types for the Gemini integration layer.
 *
 * We keep these decoupled from the @google/genai SDK surface so the rest of the
 * application only depends on our own contract, not on a third-party type that
 * may change between SDK releases.
 */

/**
 * A JSON Schema fragment as understood by Gemini's `responseSchema` option.
 * Gemini uses a (subset of) OpenAPI 3 schema. We intentionally type this loosely
 * because the SDK accepts a plain object and validates server-side.
 */
export type GeminiResponseSchema = Record<string, unknown>;

export interface GenerateJsonOptions {
  /** Override the default model for this call. */
  model?: string;
  /** Sampling temperature. Lower => more deterministic. */
  temperature?: number;
  /** Optional system instruction prepended to the prompt context. */
  systemInstruction?: string;
  /** Hard cap on output tokens. */
  maxOutputTokens?: number;
  /** Per-call timeout override in milliseconds. */
  timeoutMs?: number;
}

export interface ImageSource {
  /**
   * Raw image bytes. Mutually exclusive with `url`. Preferred for images we have
   * already streamed from S3 so we never expose a public URL to a third party.
   */
  bytes?: Buffer | Uint8Array;
  /** Publicly fetchable URL (used only when bytes are unavailable). */
  url?: string;
  /** MIME type, e.g. "image/jpeg". Required when `bytes` is provided. */
  mimeType?: string;
}

export interface AnalyzeImageOptions<TSchema = GeminiResponseSchema> {
  image: ImageSource;
  prompt: string;
  schema: TSchema;
  model?: string;
  temperature?: number;
  systemInstruction?: string;
  timeoutMs?: number;
}

/** Token usage echoed back from Gemini, normalized for our logs/metrics. */
export interface GeminiUsage {
  promptTokens: number;
  candidatesTokens: number;
  totalTokens: number;
}

export interface GeminiResult<T> {
  data: T;
  usage: GeminiUsage;
  /** Server-side response id, used for request tracing / dedupe. */
  requestId: string | null;
  model: string;
  /** Wall-clock latency of the call including retries, in milliseconds. */
  latencyMs: number;
}
