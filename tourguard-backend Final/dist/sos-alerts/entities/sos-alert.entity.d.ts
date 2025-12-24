import { User } from '../../users/entities/user.entity';
export declare enum SOSStatus {
    PENDING = "PENDING",
    ACKNOWLEDGED = "ACKNOWLEDGED",
    RESOLVED = "RESOLVED"
}
export declare class SOSAlert {
    id: string;
    user: User;
    latitude: number;
    longitude: number;
    message: string;
    status: SOSStatus;
    triggeredAt: Date;
    resolvedAt: Date;
}
