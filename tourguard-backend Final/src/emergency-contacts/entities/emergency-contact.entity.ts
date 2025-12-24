import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('emergency_contacts')
export class EmergencyContact {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    user: User;

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
