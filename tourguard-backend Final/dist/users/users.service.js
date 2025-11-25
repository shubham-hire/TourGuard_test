"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("./entities/user.entity");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const config_1 = require("@nestjs/config");
let UsersService = class UsersService {
    constructor(usersRepo, config) {
        this.usersRepo = usersRepo;
        this.config = config;
    }
    async create(userData) {
        const saltRounds = this.config.get('BCRYPT_SALT') || 10;
        const hashed = await bcrypt.hash(userData.password, saltRounds);
        const user = this.usersRepo.create({ ...userData, password: hashed });
        return this.usersRepo.save(user);
    }
    async findByEmail(email) {
        return this.usersRepo.findOne({ where: { email } });
    }
    async findByPhone(phone) {
        return this.usersRepo.findOne({ where: { phone } });
    }
    async findById(id) {
        const u = await this.usersRepo.findOne({ where: { id } });
        if (!u)
            throw new common_1.NotFoundException('User not found');
        return u;
    }
    async validateUser(email, pass) {
        const user = await this.findByEmail(email);
        if (!user)
            return null;
        const valid = await bcrypt.compare(pass, user.password);
        return valid ? user : null;
    }
    async generateHashId(userId, email, createdAt) {
        const hashData = `${userId}${email}${createdAt.toISOString()}`;
        return crypto.createHash('sha256')
            .update(hashData)
            .digest('hex')
            .substring(0, 16)
            .toUpperCase();
    }
    async setHashIdAfterOtp(userId) {
        const user = await this.findById(userId);
        user.hashId = await this.generateHashId(user.id, user.email, user.createdAt);
        user.otpVerified = true;
        console.log(`✅ OTP verified for ${user.email} | Hash ID: ${user.hashId}`);
        return this.usersRepo.save(user);
    }
    async uploadProfilePhoto(userId, photoUrl) {
        const user = await this.findById(userId);
        user.profilePhotoUrl = photoUrl;
        console.log(`📸 Profile photo uploaded for user ${userId}: ${photoUrl}`);
        return this.usersRepo.save(user);
    }
    async generateToken(user) {
        return Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
    }
    async updateLastLogin(userId) {
        await this.usersRepo.update(userId, { lastLogin: new Date() });
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        config_1.ConfigService])
], UsersService);
