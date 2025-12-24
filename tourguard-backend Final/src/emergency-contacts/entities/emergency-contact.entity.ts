import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('emergency_contacts')
export class EmergencyContact {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    // Simple string column for user identification
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
