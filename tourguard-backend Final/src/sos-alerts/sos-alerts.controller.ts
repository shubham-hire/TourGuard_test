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

    // Open: Admin Panel proxy needs access without Main Backend JWT
    @Get()
    findAll() {
        return this.service.findAll();
    }

    // Open: Admin Panel proxy needs access
    @Get('pending')
    findPending() {
        return this.service.findPending();
    }

    // Open: Admin Panel proxy needs access to update status
    @Patch(':id/status')
    updateStatus(@Param('id') id: string, @Body() dto: { status: SOSStatus }) {
        return this.service.updateStatus(id, dto.status);
    }
}

