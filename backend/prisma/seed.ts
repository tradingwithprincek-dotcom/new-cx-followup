/**
 * Dev/demo seed — creates one Store, one user per Role (all with password
 * "Password123!"), and a couple of sample Customer/FollowUp rows so the
 * Customer Module and Follow-up Module can be exercised immediately via the
 * API without hand-crafting rows first.
 *
 * Run with: npm run prisma:seed  (or: npx prisma db seed)
 */
import { PrismaClient, Role, CustomerStatus, FollowUpType, FollowUpPriority } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const DEMO_PASSWORD = 'Password123!';

async function main() {
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);

  const store = await prisma.store.upsert({
    where: { code: 'STORE-001' },
    update: {},
    create: {
      name: 'ClientBook Flagship Store',
      code: 'STORE-001',
      city: 'Dehradun',
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: 'admin@clientbook.ai' },
    update: {},
    create: {
      email: 'admin@clientbook.ai',
      fullName: 'Ada Admin',
      passwordHash,
      role: Role.ADMIN,
      storeId: store.id,
    },
  });

  const manager = await prisma.user.upsert({
    where: { email: 'manager@clientbook.ai' },
    update: {},
    create: {
      email: 'manager@clientbook.ai',
      fullName: 'Mira Manager',
      passwordHash,
      role: Role.STORE_MANAGER,
      storeId: store.id,
    },
  });

  const salesExec = await prisma.user.upsert({
    where: { email: 'sales@clientbook.ai' },
    update: {},
    create: {
      email: 'sales@clientbook.ai',
      fullName: 'Sam Sales',
      passwordHash,
      role: Role.SALES_EXEC,
      storeId: store.id,
    },
  });

  const customer = await prisma.customer.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      salesExecutiveId: salesExec.id,
      storeId: store.id,
      fullName: 'Priya Sharma',
      mobileNumber: '+919999900001',
      email: 'priya.sharma@example.com',
      status: CustomerStatus.VIP,
      lastVisitAt: new Date(),
    },
  });

  await prisma.followUp.upsert({
    where: { id: '00000000-0000-0000-0000-0000000000f1' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-0000000000f1',
      customerId: customer.id,
      salesExecutiveId: salesExec.id,
      type: FollowUpType.CALL,
      priority: FollowUpPriority.HIGH,
      notes: 'Follow up on the wishlist item she asked about last visit.',
      reminderAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    },
  });

  /* eslint-disable no-console */
  console.log('Seed complete. Demo accounts (all use the same password):');
  console.log(`  Admin        -> ${admin.email}`);
  console.log(`  Store Manager-> ${manager.email}`);
  console.log(`  Sales Exec   -> ${salesExec.email}`);
  console.log(`  Password     -> ${DEMO_PASSWORD}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
