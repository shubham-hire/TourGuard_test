import { User } from '../../users/entities/user.entity';
export declare enum IncidentSeverity {
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    CRITICAL = "CRITICAL"
}
export declare enum IncidentStatus {
    REPORTED = "REPORTED",
    ACKNOWLEDGED = "ACKNOWLEDGED",
    RESOLVED = "RESOLVED"
}
export declare class Incident {
    id: string;
    title: string;
    description: string;
    category: string;
    severity: IncidentSeverity;
    status: IncidentStatus;
    latitude: number;
    longitude: number;
    address: string;
    location: string;
    reportedBy: User;
    resolvedAt: Date;
    createdAt: Date;
}
