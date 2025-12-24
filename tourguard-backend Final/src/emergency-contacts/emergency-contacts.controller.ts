import { Controller, Post, Get, Delete, Body, Param, Req, UseGuards } from '@nestjs/common';
import { EmergencyContactsService } from './emergency-contacts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/emergency-contacts')
export class EmergencyContactsController {
    constructor(private service: EmergencyContactsService) { }

    // Made accessible without auth for hackathon (accepts userId in body)
    @Post()
    create(@Body() dto: { userId?: string; name: string; phone: string; relationship?: string; isPrimary?: boolean }) {
        // Use provided userId or a default for anonymous contacts
        const userId = dto.userId || 'anonymous';
        return this.service.create(userId, dto);
    }

    @Get()
    @UseGuards(JwtAuthGuard)
    findAll(@Req() req: any) {
        return this.service.findByUser(req.user.id);
    }

    // Get all contacts (for admin/testing)
    @Get('all')
    findAllContacts() {
        return this.service.findAll();
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard)
    delete(@Param('id') id: string, @Req() req: any) {
        return this.service.delete(id, req.user.id);
    }
}
