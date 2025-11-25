import { Controller, Post, Body, Get, UseGuards, Request } from '@nestjs/common';
import { ToursService } from './tours.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('tours')
export class ToursController {
  constructor(private toursService: ToursService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() dto: any, @Request() req) {
    return this.toursService.create(dto, req.user.userId);
  }

  @Get()
  findAll() {
    return this.toursService.findAll();
  }
}
