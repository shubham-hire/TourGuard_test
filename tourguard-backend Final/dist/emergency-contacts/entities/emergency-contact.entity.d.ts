import { User } from '../../users/entities/user.entity';
export declare class EmergencyContact {
    id: string;
    user: User | null;
    userId: string;
    name: string;
    phone: string;
    relationship: string;
    isPrimary: boolean;
    createdAt: Date;
}
