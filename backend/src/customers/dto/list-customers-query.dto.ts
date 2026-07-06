import { IsBooleanString, IsEnum, IsIn, IsOptional, IsString } from 'class-validator';
import { CustomerStatus } from '@prisma/client';

export enum RecencyFilter {
  DAYS_30 = '30',
  DAYS_60 = '60',
  DAYS_90 = '90',
}

/**
 * Backs the filter chips in the mobile "My Customers" screen:
 * status (VIP/Regular/Inactive/Lost), recency window, birthday/anniversary
 * this month, and free-text search across name/phone/product/category.
 */
export class ListCustomersQueryDto {
  @IsOptional()
  @IsEnum(CustomerStatus)
  status?: CustomerStatus;

  @IsOptional()
  @IsIn(['30', '60', '90'])
  lastVisitWithinDays?: string;

  @IsOptional()
  @IsBooleanString()
  birthdayThisMonth?: string;

  @IsOptional()
  @IsBooleanString()
  anniversaryThisMonth?: string;

  @IsOptional()
  @IsBooleanString()
  hasWishlist?: string;

  // Free-text: matches name, phone, invoice number, product, or category.
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  cursor?: string; // last seen customer id, for pagination

  @IsOptional()
  @IsString()
  take?: string; // page size, defaults to 25 in the service
}
