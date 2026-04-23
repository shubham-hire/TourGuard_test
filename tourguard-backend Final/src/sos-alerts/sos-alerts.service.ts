import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SOSAlert, SOSStatus } from './entities/sos-alert.entity';
import { SafetyGateway } from '../gateways/safety.gateway';
import { IncidentSeverity } from '../incidents/entities/incident.entity';

import { IncidentsService } from '../incidents/incidents.service';

@Injectable()
export class SOSAlertsService {
    constructor(
        @InjectRepository(SOSAlert)
        private repo: Repository<SOSAlert>,
        private gateway: SafetyGateway,
        private incidentsService: IncidentsService,
    ) { }

    async create(userId: string | null, dto: { latitude: number; longitude: number; message?: string }) {
        // Try saving with user relation first; if the userId doesn't exist
        // in the users table, PostgreSQL FK constraint will reject it.
        // In that case, save without user relation so the SOS still goes through.
        let saved: SOSAlert;
        try {
            const alert = this.repo.create({
                ...dto,
                user: userId ? ({ id: userId } as any) : null,
                status: SOSStatus.PENDING,
            });
            saved = await this.repo.save(alert);
        } catch (fkError) {
            console.warn(`⚠️ SOS: userId "${userId}" not found in users table, saving without user relation`);
            const alert = this.repo.create({
                ...dto,
                user: null,
                status: SOSStatus.PENDING,
            });
            saved = await this.repo.save(alert);
        }

        // Broadcast to all connected admin clients via WebSocket
        this.gateway.server.emit('admin:alert', {
            source: userId || 'widget',
            type: 'SOS',
            timestamp: new Date().toISOString(),
            alertId: saved.id,
        });

        // Broadcast specifically for the Admin Panel UI which expects 'sos:new'
        this.gateway.server.emit('sos:new', saved);

        // Duplicate as a general incident so it shows up in Admin Panel history
        try {
            await this.incidentsService.create({
                title: 'SOS Alert',
                description: JSON.stringify({
                    originalMessage: dto.message || 'SOS Widget Triggered',
                    status: 'pending',
                    userId: userId,
                    alertId: saved.id
                }),
                severity: IncidentSeverity.CRITICAL,
                location: JSON.stringify({
                    latitude: dto.latitude,
                    longitude: dto.longitude,
                    userId: userId
                }),
                category: 'SOS'
            }, userId || undefined);
        } catch (e) {
            console.error('Failed to create shadow incident for SOS:', e);
        }

        console.log('🚨 SOS Alert created and broadcasted:', saved.id);
        return saved;
    }

    async findAll() {
        return this.repo.find({
            relations: ['user'],
            order: { triggeredAt: 'DESC' },
        });
    }

    async findPending() {
        return this.repo.find({
            where: { status: SOSStatus.PENDING },
            relations: ['user'],
            order: { triggeredAt: 'DESC' },
        });
    }

    async updateStatus(id: string, status: SOSStatus) {
        const alert = await this.repo.findOne({ where: { id } });
        if (alert) {
            alert.status = status;
            if (status === SOSStatus.RESOLVED) {
                alert.resolvedAt = new Date();
            }
            return this.repo.save(alert);
        }
        return null;
    }
}
