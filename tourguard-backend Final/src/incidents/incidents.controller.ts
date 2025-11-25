import { Controller, Post, Body, UseGuards, Request, Get } from '@nestjs/common';
import { IncidentsService } from './incidents.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('incidents')
export class IncidentsController {
  constructor(private incidentsService: IncidentsService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  report(@Body() dto: any, @Request() req) {
    return this.incidentsService.create(dto, req.user.userId);
  }

  @Get()
  list() {
    return this.incidentsService.findAll();
  }
}
