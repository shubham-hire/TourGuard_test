import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { User } from './entities/user.entity';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    private config: ConfigService,
    private jwtService: JwtService,
  ) { }

  async create(userData: Partial<User>): Promise<User> {
    const saltConfig = this.config.get<string>('BCRYPT_SALT');
    const saltRounds = Number(saltConfig ?? 10);
    const hashed = await bcrypt.hash(userData.password, saltRounds);
    const user = this.usersRepo.create({ ...userData, password: hashed });
    return this.usersRepo.save(user);
  }

  async findByEmail(email: string) {
    return this.usersRepo.findOne({ where: { email } });
  }

  async findByPhone(phone: string) {
    return this.usersRepo.findOne({ where: { phone } });
  }

  async findById(id: string) {
    const u = await this.usersRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('User not found');
    return u;
  }

  async validateUser(email: string, pass: string): Promise<User | null> {
    const user = await this.findByEmail(email);
    if (!user) return null;
    const valid = await bcrypt.compare(pass, user.password);
    return valid ? user : null;
  }

  async generateHashId(userId: string, email: string, createdAt: Date): Promise<string> {
    const hashData = `${userId}${email}${createdAt.toISOString()}`;
    return crypto.createHash('sha256')
      .update(hashData)
      .digest('hex')
      .substring(0, 16)
      .toUpperCase();
  }

  async setHashIdAfterOtp(userId: string): Promise<User> {
    const user = await this.findById(userId);
    user.hashId = await this.generateHashId(user.id, user.email, user.createdAt);
    user.otpVerified = true;
    console.log(`✅ OTP verified for ${user.email} | Hash ID: ${user.hashId}`);
    return this.usersRepo.save(user);
  }

  async uploadProfilePhoto(userId: string, photoUrl: string): Promise<User> {
    const user = await this.findById(userId);
    user.profilePhotoUrl = photoUrl;
    console.log(`📸 Profile photo uploaded for user ${userId}: ${photoUrl}`);
    return this.usersRepo.save(user);
  }

  async generateToken(user: User): Promise<string> {
    // Generate proper JWT token
    const payload = { sub: user.id, email: user.email, role: user.role };
    return this.jwtService.sign(payload);
  }

  async updateLastLogin(userId: string): Promise<void> {
    await this.usersRepo.update(userId, { lastLogin: new Date() });
  }

  async updatePassword(phone: string, newPassword: string): Promise<User> {
    const user = await this.findByPhone(phone);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const saltConfig = this.config.get<string>('BCRYPT_SALT');
    const saltRounds = Number(saltConfig ?? 10);
    user.password = await bcrypt.hash(newPassword, saltRounds);

    console.log(`🔐 Password updated for user: ${user.email}`);
    return this.usersRepo.save(user);
  }
}
