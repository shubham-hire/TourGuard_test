import { EmergencyContactsService } from './emergency-contacts.service';
export declare class EmergencyContactsController {
    private service;
    constructor(service: EmergencyContactsService);
    create(dto: {
        userId?: string;
        name: string;
        phone: string;
        relationship?: string;
        isPrimary?: boolean;
    }): Promise<import("./entities/emergency-contact.entity").EmergencyContact>;
    findAll(req: any): Promise<import("./entities/emergency-contact.entity").EmergencyContact[]>;
    findAllContacts(): Promise<import("./entities/emergency-contact.entity").EmergencyContact[]>;
    delete(id: string, req: any): Promise<{
        deleted: boolean;
    }>;
}
