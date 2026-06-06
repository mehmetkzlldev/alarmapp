import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CreateAlarmDto } from './create-alarm.dto';

/**
 * PATCH /alarms/:id payload.
 *
 * All fields optional. We omit `missions` here because nested mission mutation goes
 * through the dedicated /alarms/:id/missions endpoints (add/remove), which keeps the
 * UNIQUE(alarm_id, order_index) invariant easy to reason about. Editing missions in a
 * bulk PATCH would require full-replace semantics that the contract does not specify.
 */
export class UpdateAlarmDto extends PartialType(
  OmitType(CreateAlarmDto, ['missions'] as const),
) {}
