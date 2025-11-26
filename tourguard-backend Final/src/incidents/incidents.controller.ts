import { Controller, Post, Body, Get } from '@nestjs/common';
import { IncidentsService } from './incidents.service';

@Controller('api/incidents')
export class IncidentsController {
  constructor(private incidentsService: IncidentsService) {}

  @Post()
  report(@Body() dto: any) {
    return this.incidentsService.create(dto);
  }

  @Get()
  list() {
    return this.incidentsService.findAll();
  }
}
