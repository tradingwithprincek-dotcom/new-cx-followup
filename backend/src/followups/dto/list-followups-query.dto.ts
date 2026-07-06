import { FollowUpPriority, FollowUpStatus, FollowUpType } from '@prisma/client';
import { IsBooleanString, IsEnum, IsIn, IsOptional, IsString } from 'class-validator';

/** "Due" bucket chips: Today / Tomorrow / This Week / Overdue. */
export enum FollowUpDueFilter {
  TODAY = 'today',
  TOMORROW = 'tomorrow',
  THIS_WEEK = 'thisWeek',
  OVERDUE = 'overdue',
}

/**
 * Backs the filter chips on the Follow-up list / Tasks screen:
 * due-date bucket, status (Pending/Completed/Rescheduled/Cancelled),
 * priority (High Priority chip), follow-up type, and which customer
 * (used when opening the list scoped to one customer's follow-ups).
 */
export class ListFollowUpsQueryDto {
  @IsOptional()
  @IsIn(Object.values(FollowUpDueFilter))
  due?: FollowUpDueFilter;

  @IsOptional()
  @IsEnum(FollowUpStatus)
  status?: FollowUpStatus;

  @IsOptional()
  @IsEnum(FollowUpPriority)
  priority?: FollowUpPriority;

  @IsOptional()
  @IsEnum(FollowUpType)
  type?: FollowUpType;

  // "Missed" isn't a stored status (see schema.prisma) — this flag asks the
  // service to derive it: status = PENDING AND reminderAt < now.
  @IsOptional()
  @IsBooleanString()
  missed?: string;

  @IsOptional()
  @IsString()
  customerId?: string;

  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @IsString()
  take?: string;
}
