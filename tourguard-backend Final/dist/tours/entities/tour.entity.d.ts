import { User } from '../../users/entities/user.entity';
export declare class Tour {
    id: string;
    title: string;
    description: string;
    destination: string;
    startDate: Date;
    endDate: Date;
    createdBy: User;
    createdAt: Date;
}
