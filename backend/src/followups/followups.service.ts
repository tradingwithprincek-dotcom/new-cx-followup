import { BadRequestException, Injectable } from '@nestjs/common';
import { FollowUpStatus, InteractionType, Prisma, FollowUpType } from '@prisma/client';
import { PrismaService } from '../prisma.module';
import { ownedBy, assertOwnsRecord, RequestUser } from '../common/repositories/ownership.util';
import { CreateFollowUpDto } from './dto/create-followup.dto';
import { UpdateFollowUpDto } from './dto/update-followup.dto';
import { ListFollowUpsQueryDto, FollowUpDueFilter } from './dto/list-followups-query.dto';

const DEFAULT_PAGE_SIZE = 25;

// A Follow-up's `type` (CALL/WHATSAPP/VISIT) and the Timeline's
// `InteractionType` are deliberately separate enums — Interaction also
// needs PURCHASE/NOTE/WISHLIST/etc values a Follow-up can never take — so
// completing a follow-up maps one onto the other here.
const FOLLOW_UP_TYPE_TO_INTERACTION_TYPE: Record<FollowUpType, InteractionType> = {
  CALL: InteractionType.CALL,
  WHATSAPP: InteractionType.WHATSAPP,
  VISIT: InteractionType.VISIT,
};

@Injectable()
export class FollowUpsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Every Follow-up belongs to one Customer, and only the rep who owns that
   * customer may create a follow-up for them — checked here rather than
   * trusting the client-supplied customerId.
   */
  async create(user: RequestUser, dto: CreateFollowUpDto) {
    const customer = await this.prisma.customer.findUnique({ where: { id: dto.customerId } });
    assertOwnsRecord(user, customer);

    const followUp = await this.prisma.followUp.create({
      data: {
        customerId: dto.customerId,
        salesExecutiveId: user.id,
        type: dto.type,
        priority: dto.priority ?? undefined,
        notes: dto.notes,
        reminderAt: new Date(dto.reminderAt),
      },
    });

    // Every Follow-up automatically creates a Timeline entry (spec §3) —
    // this is the "a reminder was scheduled" entry; completing it later
    // adds a second, separate entry for the actual Call/WhatsApp/Visit.
    await this.prisma.interaction.create({
      data: {
        customerId: dto.customerId,
        salesExecutiveId: user.id,
        type: InteractionType.REMINDER,
        notes: dto.notes ?? `${dto.type} follow-up scheduled`,
        metadata: { followUpId: followUp.id },
      },
    });

    return followUp;
  }

  async update(user: RequestUser, id: string, dto: UpdateFollowUpDto) {
    const existing = await this.prisma.followUp.findUnique({ where: { id } });
    assertOwnsRecord(user, existing);

    if (dto.status === FollowUpStatus.COMPLETED) {
      throw new BadRequestException('Use POST /followups/:id/complete to mark a follow-up completed');
    }

    return this.prisma.followUp.update({
      where: { id },
      data: {
        type: dto.type,
        priority: dto.priority,
        notes: dto.notes,
        status: dto.status,
        reminderAt: dto.reminderAt ? new Date(dto.reminderAt) : undefined,
      },
    });
  }

  async delete(user: RequestUser, id: string) {
    const existing = await this.prisma.followUp.findUnique({ where: { id } });
    assertOwnsRecord(user, existing);
    await this.prisma.followUp.delete({ where: { id } });
    return { id, deleted: true };
  }

  async detail(user: RequestUser, id: string) {
    const followUp = await this.prisma.followUp.findUnique({ where: { id } });
    assertOwnsRecord(user, followUp);
    return followUp;
  }

  /**
   * Marks a follow-up COMPLETED and writes the matching Customer Timeline
   * entry (Call/WhatsApp/Visit) — the business rule that "every completed
   * Follow-up must be added to Customer Timeline" is enforced here, in one
   * transaction, so the two can never drift apart.
   */
  async complete(user: RequestUser, id: string) {
    const existing = await this.prisma.followUp.findUnique({ where: { id } });
    assertOwnsRecord(user, existing);

    if (existing!.status === FollowUpStatus.COMPLETED) {
      return existing;
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.followUp.update({
        where: { id },
        data: { status: FollowUpStatus.COMPLETED, completedAt: new Date() },
      }),
      this.prisma.interaction.create({
        data: {
          customerId: existing!.customerId,
          salesExecutiveId: user.id,
          type: FOLLOW_UP_TYPE_TO_INTERACTION_TYPE[existing!.type],
          notes: existing!.notes,
          metadata: { followUpId: id },
        },
      }),
    ]);

    return updated;
  }

  /**
   * Follow-up list + calendar view. Every "due" chip in the mobile UI maps
   * to a clause here; `ownedBy` guarantees a rep can never see another
   * rep's follow-ups regardless of what a client sends.
   */
  async list(user: RequestUser, query: ListFollowUpsQueryDto) {
    const take = Math.min(Number(query.take) || DEFAULT_PAGE_SIZE, 100);
    const now = new Date();

    const where: Prisma.FollowUpWhereInput = ownedBy(user, {
      ...(query.customerId ? { customerId: query.customerId } : {}),
      ...(query.status ? { status: query.status } : {}),
      ...(query.priority ? { priority: query.priority } : {}),
      ...(query.type ? { type: query.type } : {}),
      ...(query.missed === 'true'
        ? { status: FollowUpStatus.PENDING, reminderAt: { lt: now } }
        : {}),
      ...(query.due ? dueRangeClause(query.due, now) : {}),
    });

    const followUps = await this.prisma.followUp.findMany({
      where,
      take: take + 1, // over-fetch by 1 to know if there's a next page
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: [{ reminderAt: 'asc' }],
      include: { customer: { select: { id: true, fullName: true, mobileNumber: true, photoUrl: true } } },
    });

    const hasMore = followUps.length > take;
    const page = hasMore ? followUps.slice(0, take) : followUps;

    return {
      items: page,
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  /** Powers the Dashboard's Follow-up cards. */
  async dashboardSummary(user: RequestUser) {
    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);
    const tomorrowStart = startOfDay(addDays(now, 1));
    const tomorrowEnd = endOfDay(addDays(now, 1));

    const [todayCount, pendingCount, completedTodayCount, missedCount, upcomingTomorrowCount] =
      await Promise.all([
        this.prisma.followUp.count({
          where: ownedBy(user, { reminderAt: { gte: todayStart, lte: todayEnd } }),
        }),
        this.prisma.followUp.count({
          where: ownedBy(user, { status: FollowUpStatus.PENDING }),
        }),
        this.prisma.followUp.count({
          where: ownedBy(user, {
            status: FollowUpStatus.COMPLETED,
            completedAt: { gte: todayStart, lte: todayEnd },
          }),
        }),
        this.prisma.followUp.count({
          where: ownedBy(user, { status: FollowUpStatus.PENDING, reminderAt: { lt: now } }),
        }),
        this.prisma.followUp.count({
          where: ownedBy(user, { reminderAt: { gte: tomorrowStart, lte: tomorrowEnd } }),
        }),
      ]);

    return {
      todayCount,
      pendingCount,
      completedTodayCount,
      missedCount,
      upcomingTomorrowCount,
    };
  }
}

function dueRangeClause(due: FollowUpDueFilter, now: Date): Prisma.FollowUpWhereInput {
  switch (due) {
    case FollowUpDueFilter.TODAY:
      return { reminderAt: { gte: startOfDay(now), lte: endOfDay(now) } };
    case FollowUpDueFilter.TOMORROW:
      return { reminderAt: { gte: startOfDay(addDays(now, 1)), lte: endOfDay(addDays(now, 1)) } };
    case FollowUpDueFilter.THIS_WEEK:
      return { reminderAt: { gte: startOfDay(now), lte: endOfDay(endOfISOWeek(now)) } };
    case FollowUpDueFilter.OVERDUE:
      return { status: FollowUpStatus.PENDING, reminderAt: { lt: startOfDay(now) } };
    default:
      return {};
  }
}

function startOfDay(d: Date): Date {
  const r = new Date(d);
  r.setHours(0, 0, 0, 0);
  return r;
}

function endOfDay(d: Date): Date {
  const r = new Date(d);
  r.setHours(23, 59, 59, 999);
  return r;
}

function addDays(d: Date, days: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + days);
  return r;
}

// Sunday-terminated week to keep the "This Week" chip predictable regardless
// of what day it is when the rep taps it (today .. end of this calendar week).
function endOfISOWeek(d: Date): Date {
  const r = new Date(d);
  const day = r.getDay(); // 0 (Sun) .. 6 (Sat)
  const daysUntilSunday = 7 - day === 7 ? 0 : 7 - day;
  r.setDate(r.getDate() + daysUntilSunday);
  return r;
}
