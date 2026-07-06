import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.module';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        role: true,
        storeId: true,
        virtualPhoneNumber: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async listByStore(storeId: string) {
    return this.prisma.user.findMany({
      where: { storeId },
      select: { id: true, fullName: true, role: true, isActive: true, createdAt: true },
      orderBy: { fullName: 'asc' },
    });
  }
}
