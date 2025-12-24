import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EmergencyContact } from './entities/emergency-contact.entity';

@Injectable()
export class EmergencyContactsService {
    constructor(
        @InjectRepository(EmergencyContact)
        private repo: Repository<EmergencyContact>,
    ) { }

    async create(userId: string, dto: { name: string; phone: string; relationship?: string; isPrimary?: boolean }) {
        const contact = this.repo.create({
            name: dto.name,
            phone: dto.phone,
            relationship: dto.relationship,
            isPrimary: dto.isPrimary ?? false,
            userId: userId,
        });
        return this.repo.save(contact);
    }

    async findByUser(userId: string) {
        return this.repo.find({
            where: { userId: userId },
            order: { isPrimary: 'DESC', createdAt: 'ASC' },
        });
    }

    async findAll() {
        return this.repo.find({
            order: { createdAt: 'DESC' },
        });
    }

    async delete(id: string, userId: string) {
        const contact = await this.repo.findOne({
            where: { id, userId: userId },
        });
        if (contact) {
            await this.repo.remove(contact);
            return { deleted: true };
        }
        return { deleted: false };
    }
}
