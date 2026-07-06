import { FollowUpPriority, FollowUpStatus, FollowUpType } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Backs "Edit Follow-up". All fields optional — a reschedule only sends
 * `reminderAt` (+ `status: RESCHEDULED`), a priority bump only sends
 * `priority`, etc. Marking a follow-up COMPLETED goes through the dedicated
 * `POST /followups/:id/complete` endpoint instead, since that action also
 * has to write a Customer Timeline entry — see followups.service.ts.
 */
export class UpdateFollowUpDto {
  @IsOptional()
  @IsEnum(FollowUpType)
  type?: FollowUpType;

  @IsOptional()
  @IsEnum(FollowUpPriority)
  priority?: FollowUpPriority;

  @IsOptional()
  @IsDateString()
  reminderAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  // Only RESCHEDULED / CANCELLED / PENDING are valid here — COMPLETED is
  // rejected in the service and must go through the /complete endpoint.
  @IsOptional()
  @IsEnum(FollowUpStatus)
  status?: FollowUpStatus;
}
