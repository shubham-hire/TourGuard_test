import { User } from '../../users/entities/user.entity';
export declare class Tour {
    id: string;
    title: string;
    description: string;
    location: string;
    meta: any;
    createdBy: User;
    createdAt: Date;
}
