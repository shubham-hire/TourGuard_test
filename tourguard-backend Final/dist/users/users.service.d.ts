import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { ConfigService } from '@nestjs/config';
export declare class UsersService {
    private usersRepo;
    private config;
    constructor(usersRepo: Repository<User>, config: ConfigService);
    create(userData: Partial<User>): Promise<User>;
    findByEmail(email: string): Promise<User>;
    findByPhone(phone: string): Promise<User>;
    findById(id: string): Promise<User>;
    validateUser(email: string, pass: string): Promise<User | null>;
    generateHashId(userId: string, email: string, createdAt: Date): Promise<string>;
    setHashIdAfterOtp(userId: string): Promise<User>;
    uploadProfilePhoto(userId: string, photoUrl: string): Promise<User>;
    generateToken(user: User): Promise<string>;
    updateLastLogin(userId: string): Promise<void>;
    updatePassword(phone: string, newPassword: string): Promise<User>;
}
