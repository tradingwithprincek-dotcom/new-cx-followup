import { ForbiddenException } from '@nestjs/common';

/**
 * Layer 2 of the "a rep only ever sees their own customers" rule.
 *
 * Layer 1 (RolesGuard, Milestone 1) rejects requests from the wrong role
 * entirely. This layer makes it structurally impossible for a bug in a
 * controller to leak another rep's rows even when the role is correct —
 * every Customer-linked query MUST pass through here rather than trusting
 * a client-supplied salesExecutiveId.
 *
 * Usage in a service:
 *   const where = ownedBy(currentUser, { status: 'VIP' });
 *   this.prisma.customer.findMany({ where });
 */
export interface RequestUser {
  id: string;
  role: 'SALES_EXEC' | 'STORE_MANAGER' | 'ADMIN';
  storeId: string;
}

export function ownedBy<T extends Record<string, any>>(user: RequestUser, extraWhere: T = {} as T) {
  if (user.role !== 'SALES_EXEC') {
    // Managers/Admins never get a "my customers" view — they only ever get
    // the aggregate report endpoints (separate module, separate queries).
    throw new ForbiddenException('This endpoint is only available to sales executives');
  }
  return { ...extraWhere, salesExecutiveId: user.id };
}

/**
 * For a single-record fetch (e.g. GET /customers/:id), verifies the row
 * actually belongs to the requesting rep before returning it — never trust
 * the :id alone.
 */
export function assertOwnsRecord(user: RequestUser, record: { salesExecutiveId: string } | null) {
  if (!record || record.salesExecutiveId !== user.id) {
    // Same 404 whether it doesn't exist or belongs to someone else —
    // don't leak which is the case.
    throw new ForbiddenException('Customer not found');
  }
}
