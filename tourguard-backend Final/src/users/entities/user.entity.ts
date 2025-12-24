import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum UserRole { USER = 'USER', ADMIN = 'ADMIN' }

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column({ nullable: true })
  name: string;

  @Column({ type: 'text', default: UserRole.USER })
  role: UserRole;

  @Column({ nullable: true })
  phone?: string;

  @Column({ nullable: true, length: 32 })
  hashId?: string;

  @Column({ nullable: true, length: 500 })
  profilePhotoUrl?: string;

  @Column({ default: false })
  otpVerified: boolean;

  @Column({ type: 'timestamp', nullable: true })
  lastLogin?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
