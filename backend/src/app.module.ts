import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CustomersModule } from './customers/customers.module';
import { FollowUpsModule } from './followups/followups.module';
import { PrismaModule } from './prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env' }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]), // basic API rate limiting
    PrismaModule,
    AuthModule,
    UsersModule,
    CustomersModule,
    FollowUpsModule,
  ],
  providers: [
    // Without this, @Throttle() on the login route (auth.controller.ts) is
    // registered metadata but never enforced — ThrottlerModule.forRoot()
    // alone only configures limits, it doesn't attach a guard to any route.
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
