import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { FollowUpsService } from './followups.service';
import { CreateFollowUpDto } from './dto/create-followup.dto';
import { UpdateFollowUpDto } from './dto/update-followup.dto';
import { ListFollowUpsQueryDto } from './dto/list-followups-query.dto';

/**
 * Follow-up Management — SALES_EXEC only, same shape as CustomersController:
 * no STORE_MANAGER/ADMIN path exists into this controller at all. Managers
 * get follow-up *counts* through the aggregate reports module (later
 * milestone), never the individual follow-up rows or notes.
 */
@Controller('api/v1/followups')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SALES_EXEC)
export class FollowUpsController {
  constructor(private followUpsService: FollowUpsService) {}

  @Get()
  async list(@Req() req: any, @Query() query: ListFollowUpsQueryDto) {
    return this.followUpsService.list(req.user, query);
  }

  @Get('dashboard-summary')
  async dashboardSummary(@Req() req: any) {
    return this.followUpsService.dashboardSummary(req.user);
  }

  @Get(':id')
  async detail(@Req() req: any, @Param('id') id: string) {
    return this.followUpsService.detail(req.user, id);
  }

  @Post()
  async create(@Req() req: any, @Body() dto: CreateFollowUpDto) {
    return this.followUpsService.create(req.user, dto);
  }

  @Patch(':id')
  async update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateFollowUpDto) {
    return this.followUpsService.update(req.user, id, dto);
  }

  @Post(':id/complete')
  async complete(@Req() req: any, @Param('id') id: string) {
    return this.followUpsService.complete(req.user, id);
  }

  @Delete(':id')
  async remove(@Req() req: any, @Param('id') id: string) {
    return this.followUpsService.delete(req.user, id);
  }
}
