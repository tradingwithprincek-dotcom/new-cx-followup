import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UsersService } from './users.service';

@Controller('api/v1/users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  // Any authenticated role can read their own profile.
  @Get('me')
  async me(@Req() req: any) {
    return this.usersService.findById(req.user.id);
  }

  // Admin-only: list all sales executives/managers in the org.
  // This is the reporting surface — it returns roster data, never a rep's
  // customer notes/timeline (those endpoints don't exist for this role at all,
  // see ARCHITECTURE.md §4).
  @Get('roster')
  @Roles(Role.ADMIN, Role.STORE_MANAGER)
  async roster(@Req() req: any) {
    return this.usersService.listByStore(req.user.storeId);
  }
}
