import { FollowUpPriority, FollowUpType } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

/**
 * Backs the "Create Follow-up" screen. `reminderAt` is a single combined
 * date+time ISO string — the mobile date picker and time picker both write
 * into this one field before submitting, so the API never has to reconcile
 * two separate columns.
 */
export class CreateFollowUpDto {
  @IsUUID()
  customerId: string;

  @IsEnum(FollowUpType)
  type: FollowUpType;

  @IsOptional()
  @IsEnum(FollowUpPriority)
  priority?: FollowUpPriority;

  @IsDateString()
  reminderAt: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
