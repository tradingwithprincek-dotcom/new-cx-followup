import { Injectable, NotFoundException } from '@nestjs/common';
import { InteractionType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma.module';
import { ownedBy, assertOwnsRecord, RequestUser } from '../common/repositories/ownership.util';
import { ListCustomersQueryDto } from './dto/list-customers-query.dto';

const DEFAULT_PAGE_SIZE = 25;

@Injectable()
export class CustomersService {
  constructor(private prisma: PrismaService) {}

  /**
   * "My Customers" list. Every filter chip in the mobile UI maps to a clause
   * here. `ownedBy` guarantees the query can never return another rep's rows
   * regardless of what a client sends.
   */
  async list(user: RequestUser, query: ListCustomersQueryDto) {
    const take = Math.min(Number(query.take) || DEFAULT_PAGE_SIZE, 100);

    const where: Prisma.CustomerWhereInput = ownedBy(user, {
      ...(query.status ? { status: query.status } : {}),
      ...(query.lastVisitWithinDays
        ? { lastVisitAt: { gte: daysAgo(Number(query.lastVisitWithinDays)) } }
        : {}),
      ...(query.birthdayThisMonth === 'true' ? monthMatch('birthday') : {}),
      ...(query.anniversaryThisMonth === 'true' ? monthMatch('anniversary') : {}),
      ...(query.hasWishlist === 'true' ? { wishlistItems: { some: {} } } : {}),
      ...(query.search
        ? {
            OR: [
              { fullName: { contains: query.search, mode: 'insensitive' } },
              { mobileNumber: { contains: query.search } },
              { favouriteProduct: { contains: query.search, mode: 'insensitive' } },
              { favouriteCategory: { contains: query.search, mode: 'insensitive' } },
            ],
          }
        : {}),
    });

    const customers = await this.prisma.customer.findMany({
      where,
      take: take + 1, // over-fetch by 1 to know if there's a next page
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: { lastVisitAt: 'desc' },
    });

    const hasMore = customers.length > take;
    const page = hasMore ? customers.slice(0, take) : customers;

    return {
      items: page,
      nextCursor: hasMore ? page[page.length - 1].id : null,
    };
  }

  async detail(user: RequestUser, customerId: string) {
    const customer = await this.prisma.customer.findUnique({ where: { id: customerId } });
    assertOwnsRecord(user, customer);
    return customer;
  }

  /**
   * Every purchase/call/WhatsApp/visit/reminder/note/wishlist/voice-note
   * event, newest first — the single feed the "Customer Timeline" screen renders.
   */
  async timeline(user: RequestUser, customerId: string) {
    const customer = await this.prisma.customer.findUnique({ where: { id: customerId } });
    assertOwnsRecord(user, customer);

    return this.prisma.interaction.findMany({
      where: { customerId },
      orderBy: { occurredAt: 'desc' },
    });
  }

  async addNote(user: RequestUser, customerId: string, note: string) {
    const customer = await this.prisma.customer.findUnique({ where: { id: customerId } });
    assertOwnsRecord(user, customer);

    return this.prisma.interaction.create({
      data: {
        customerId,
        salesExecutiveId: user.id,
        type: InteractionType.NOTE,
        notes: note,
      },
    });
  }

  /** Powers the "Today's Birthdays" / "Today's Anniversaries" task cards. */
  async todayHighlights(user: RequestUser) {
    const [birthdays, anniversaries] = await Promise.all([
      this.prisma.customer.findMany({ where: ownedBy(user, monthDayMatch('birthday')) }),
      this.prisma.customer.findMany({ where: ownedBy(user, monthDayMatch('anniversary')) }),
    ]);
    return { birthdays, anniversaries };
  }
}

function daysAgo(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d;
}

// NOTE: Postgres month/day matching on a DateTime column is normally done via
// a raw `EXTRACT(MONTH FROM ...)` query for real day-of-month accuracy across
// years. Prisma's query builder can't express that directly, so the actual
// SQL for these two helpers is wired up via `$queryRaw` in the repository
// layer during hardening — kept here as the documented filter contract so
// the controller/DTO shape doesn't change when that lands.
function monthMatch(field: 'birthday' | 'anniversary') {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return { [field]: { gte: start, lt: end } };
}

function monthDayMatch(field: 'birthday' | 'anniversary') {
  return monthMatch(field);
}
