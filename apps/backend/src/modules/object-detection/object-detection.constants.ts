/**
 * The closed set of objects the wake-up "find an object" mission supports.
 * Kept as a single source of truth so the DTO validation, the Gemini prompt,
 * and the AI-mission generator all agree.
 */
export const SUPPORTED_OBJECTS = [
  'toothbrush',
  'sink',
  'coffee mug',
  'keys',
  'shoes',
  'laptop',
] as const;

export type SupportedObject = (typeof SUPPORTED_OBJECTS)[number];

export function isSupportedObject(value: string): value is SupportedObject {
  return (SUPPORTED_OBJECTS as readonly string[]).includes(value);
}

/**
 * Confidence floor for a detection to count as a match. Tuned conservatively so
 * a user cannot pass the alarm by waving a vaguely-similar object at the camera.
 */
export const DETECTION_MATCH_THRESHOLD = 0.6;
