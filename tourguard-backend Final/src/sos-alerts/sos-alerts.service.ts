import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SOSAlert, SOSStatus } from './entities/sos-alert.entity';

@Injectable()
export class SOSAlertsService {
    constructor(
        @InjectRepository(SOSAlert)
        private repo: Repository<SOSAlert>,
    ) { }

    async create(userId: string | null, dto: { latitude: number; longitude: number; message?: string }) {
        const alert = this.repo.create({
            ...dto,
            user: userId ? ({ id: userId } as any) : null,
            status: SOSStatus.PENDING,
        });
        return this.repo.save(alert);
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
