import { Repository } from 'typeorm';
import { SOSAlert, SOSStatus } from './entities/sos-alert.entity';
export declare class SOSAlertsService {
    private repo;
    constructor(repo: Repository<SOSAlert>);
    create(userId: string | null, dto: {
        latitude: number;
        longitude: number;
        message?: string;
    }): Promise<SOSAlert>;
    findAll(): Promise<SOSAlert[]>;
    findPending(): Promise<SOSAlert[]>;
    updateStatus(id: string, status: SOSStatus): Promise<SOSAlert>;
}
