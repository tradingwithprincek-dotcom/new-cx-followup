import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CustomersService } from './customers.service';
import { ListCustomersQueryDto } from './dto/list-customers-query.dto';
import { AddNoteDto } from './dto/add-note.dto';

/**
 * "My Customers" — SALES_EXEC only. There is deliberately no
 * STORE_MANAGER/ADMIN path into this controller at all; their reporting
 * needs are served by a separate, aggregate-only reports module so a typo
 * in a guard here can't accidentally expose a rep's personal notes.
 */
@Controller('api/v1/customers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SALES_EXEC)
export class CustomersController {
  constructor(private customersService: CustomersService) {}

  @Get()
  async list(@Req() req: any, @Query() query: ListCustomersQueryDto) {
    return this.customersService.list(req.user, query);
  }

  @Get('today-highlights')
  async todayHighlights(@Req() req: any) {
    return this.customersService.todayHighlights(req.user);
  }

  @Get(':id')
  async detail(@Req() req: any, @Param('id') id: string) {
    return this.customersService.detail(req.user, id);
  }

  @Get(':id/timeline')
  async timeline(@Req() req: any, @Param('id') id: string) {
    return this.customersService.timeline(req.user, id);
  }

  @Post(':id/notes')
  async addNote(@Req() req: any, @Param('id') id: string, @Body() dto: AddNoteDto) {
    return this.customersService.addNote(req.user, id, dto.note);
  }
}
