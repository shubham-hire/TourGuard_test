import { User } from '../../users/entities/user.entity';
export declare enum IncidentSeverity {
    LOW = "LOW",
    MEDIUM = "MEDIUM",
    HIGH = "HIGH",
    CRITICAL = "CRITICAL"
}
export declare class Incident {
    id: string;
    title: string;
    description: string;
    severity: IncidentSeverity;
    location: string | null;
    reportedBy: User;
    createdAt: Date;
}
