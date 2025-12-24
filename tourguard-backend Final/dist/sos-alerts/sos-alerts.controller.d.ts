import { SOSAlertsService } from './sos-alerts.service';
import { SOSStatus } from './entities/sos-alert.entity';
export declare class SOSAlertsController {
    private service;
    constructor(service: SOSAlertsService);
    create(dto: {
        userId?: string;
        latitude: number;
        longitude: number;
        message?: string;
    }): Promise<import("./entities/sos-alert.entity").SOSAlert>;
    findAll(): Promise<import("./entities/sos-alert.entity").SOSAlert[]>;
    findPending(): Promise<import("./entities/sos-alert.entity").SOSAlert[]>;
    updateStatus(id: string, dto: {
        status: SOSStatus;
    }): Promise<import("./entities/sos-alert.entity").SOSAlert>;
}
