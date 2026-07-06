import { SetMetadata } from '@nestjs/common';
import { Role } from '@prisma/client';

export const ROLES_KEY = 'roles';
/**
 * Restrict a controller/handler to specific roles.
 * Usage: @Roles(Role.SALES_EXEC)
 */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
