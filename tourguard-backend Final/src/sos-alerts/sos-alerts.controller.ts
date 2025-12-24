import { Controller, Post, Get, Patch, Body, Param } from '@nestjs/common';
import { SOSAlertsService } from './sos-alerts.service';
import { SOSStatus } from './entities/sos-alert.entity';

@Controller('api/sos-alerts')
export class SOSAlertsController {
    constructor(private service: SOSAlertsService) { }

    @Post()
    create(@Body() dto: { userId?: string; latitude: number; longitude: number; message?: string }) {
        return this.service.create(dto.userId || null, dto);
    }

    @Get()
    findAll() {
        return this.service.findAll();
    }

    @Get('pending')
    findPending() {
        return this.service.findPending();
    }

    @Patch(':id/status')
    updateStatus(@Param('id') id: string, @Body() dto: { status: SOSStatus }) {
        return this.service.updateStatus(id, dto.status);
    }
}
