import { Controller, Post, Body, Get, UseGuards } from '@nestjs/common';
import { IncidentsService } from './incidents.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/incidents')
export class IncidentsController {
  constructor(private incidentsService: IncidentsService) {}

  // Allow anonymous incident reports for safety
  @Post()
  report(@Body() dto: any) {
    return this.incidentsService.create(dto);
  }

  // Protected: Only authenticated users can view all incidents
  @Get()
  @UseGuards(JwtAuthGuard)
  list() {
    return this.incidentsService.findAll();
  }
}
