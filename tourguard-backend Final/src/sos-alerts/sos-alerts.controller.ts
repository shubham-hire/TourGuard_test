import { Controller, Post, Get, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { SOSAlertsService } from './sos-alerts.service';
import { SOSStatus } from './entities/sos-alert.entity';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/sos-alerts')
export class SOSAlertsController {
    constructor(private service: SOSAlertsService) { }

    // Allow SOS without auth - emergency situations
    @Post()
    create(@Body() dto: { userId?: string; latitude: number; longitude: number; message?: string }) {
        return this.service.create(dto.userId || null, dto);
    }

    // Protected: Only authenticated users/admins can view all alerts
    @Get()
    @UseGuards(JwtAuthGuard)
    findAll() {
        return this.service.findAll();
    }

    // Protected: Only authenticated users/admins can view pending alerts
    @Get('pending')
    @UseGuards(JwtAuthGuard)
    findPending() {
        return this.service.findPending();
    }

    // Protected: Only authenticated admins can update status
    @Patch(':id/status')
    @UseGuards(JwtAuthGuard)
    updateStatus(@Param('id') id: string, @Body() dto: { status: SOSStatus }) {
        return this.service.updateStatus(id, dto.status);
    }
}

