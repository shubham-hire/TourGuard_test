import { Controller, Post, Get, Delete, Body, Param, Req, UseGuards } from '@nestjs/common';
import { EmergencyContactsService } from './emergency-contacts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/emergency-contacts')
export class EmergencyContactsController {
    constructor(private service: EmergencyContactsService) { }

    // Protected: Must be authenticated to add contacts
    @Post()
    @UseGuards(JwtAuthGuard)
    create(
        @Body() dto: { name: string; phone: string; relationship?: string; isPrimary?: boolean },
        @Req() req: any,
    ) {
        return this.service.create(req.user.id, dto);
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

    // Clear all contacts for the authenticated user
    @Delete('user/clear')
    @UseGuards(JwtAuthGuard)
    clearUserContacts(@Req() req: any) {
        return this.service.deleteAllForUser(req.user.id);
    }

    // Admin: Truncate all contacts (for testing/reset)
    @Delete('admin/truncate-all')
    truncateAll() {
        return this.service.truncateAll();
    }
}
