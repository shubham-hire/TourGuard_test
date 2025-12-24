import { Controller, Post, Get, Delete, Body, Param, Req, UseGuards } from '@nestjs/common';
import { EmergencyContactsService } from './emergency-contacts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/emergency-contacts')
export class EmergencyContactsController {
    constructor(private service: EmergencyContactsService) { }

    @Post()
    @UseGuards(JwtAuthGuard)
    create(@Req() req: any, @Body() dto: { name: string; phone: string; relationship?: string; isPrimary?: boolean }) {
        return this.service.create(req.user.id, dto);
    }

    @Get()
    @UseGuards(JwtAuthGuard)
    findAll(@Req() req: any) {
        return this.service.findByUser(req.user.id);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard)
    delete(@Param('id') id: string, @Req() req: any) {
        return this.service.delete(id, req.user.id);
    }
}
