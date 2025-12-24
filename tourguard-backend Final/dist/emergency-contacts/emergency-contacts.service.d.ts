import { Repository } from 'typeorm';
import { EmergencyContact } from './entities/emergency-contact.entity';
export declare class EmergencyContactsService {
    private repo;
    constructor(repo: Repository<EmergencyContact>);
    create(userId: string, dto: {
        name: string;
        phone: string;
        relationship?: string;
        isPrimary?: boolean;
    }): Promise<EmergencyContact>;
    findByUser(userId: string): Promise<EmergencyContact[]>;
    findAll(): Promise<EmergencyContact[]>;
    delete(id: string, userId: string): Promise<{
        deleted: boolean;
    }>;
}
