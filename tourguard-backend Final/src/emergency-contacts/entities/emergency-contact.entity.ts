import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('emergency_contacts')
export class EmergencyContact {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    // Optional relationship to User - nullable for anonymous/unregistered users
    @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
    user: User | null;

    // Store userId as string for cases where user doesn't exist in DB
    @Column({ nullable: true })
    userId: string;

    @Column()
    name: string;

    @Column()
    phone: string;

    @Column({ nullable: true })
    relationship: string;

    @Column({ default: false })
    isPrimary: boolean;

    @CreateDateColumn()
    createdAt: Date;
}
