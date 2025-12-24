import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum SOSStatus {
    PENDING = 'PENDING',
    ACKNOWLEDGED = 'ACKNOWLEDGED',
    RESOLVED = 'RESOLVED',
}

@Entity('sos_alerts')
export class SOSAlert {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
    user: User;

    @Column({ type: 'decimal', precision: 10, scale: 7 })
    latitude: number;

    @Column({ type: 'decimal', precision: 10, scale: 7 })
    longitude: number;

    @Column({ type: 'text', nullable: true })
    message: string;

    @Column({ type: 'text', default: SOSStatus.PENDING })
    status: SOSStatus;

    @CreateDateColumn()
    triggeredAt: Date;

    @Column({ type: 'timestamp', nullable: true })
    resolvedAt: Date;
}
