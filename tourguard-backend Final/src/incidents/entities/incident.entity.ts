import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum IncidentSeverity { LOW='LOW', MEDIUM='MEDIUM', HIGH='HIGH', CRITICAL='CRITICAL' }

@Entity('incidents')
export class Incident {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  description: string;

  @Column({ type: 'enum', enum: IncidentSeverity, default: IncidentSeverity.MEDIUM })
  severity: IncidentSeverity;

  @Column({ type: 'json', nullable: true })
  location: { lat: number; lng: number } | null;

  @ManyToOne(() => User, { nullable: true })
  reportedBy: User;

  @CreateDateColumn()
  createdAt: Date;
}
