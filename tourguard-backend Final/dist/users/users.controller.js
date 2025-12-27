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
exports.UsersController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const users_service_1 = require("./users.service");
const create_user_dto_1 = require("./dto/create-user.dto");
const multer_config_1 = require("../config/multer.config");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let UsersController = class UsersController {
    constructor(usersService) {
        this.usersService = usersService;
    }
    async register(dto) {
        const existingUser = await this.usersService.findByPhone(dto.phone) ||
            await this.usersService.findByEmail(dto.email);
        if (existingUser) {
            throw new common_1.HttpException('User already exists with this email or phone', common_1.HttpStatus.CONFLICT);
        }
        const created = await this.usersService.create(dto);
        const token = await this.usersService.generateToken(created);
        return {
            success: true,
            message: 'Registration successful',
            data: {
                id: created.id,
                name: created.name,
                email: created.email,
                phone: created.phone,
                token,
            },
        };
    }
    async getOne(id) {
        const u = await this.usersService.findById(id);
        delete u.password;
        return u;
    }
    async uploadPhoto(file, req) {
        if (!file) {
            throw new common_1.HttpException('No photo file provided', common_1.HttpStatus.BAD_REQUEST);
        }
        const photoUrl = `/uploads/profile-photos/${file.filename}`;
        await this.usersService.uploadProfilePhoto(req.user.userId, photoUrl);
        return {
            success: true,
            message: 'Profile photo uploaded successfully',
            data: { photoUrl },
        };
    }
    async updateLocation(body, req) {
        console.log(`Location update from user ${req.user.userId}: ${body.lat}, ${body.lng}`);
        return {
            success: true,
            message: 'Location received',
        };
    }
    async logActivity(body, req) {
        console.log(`Activity from user ${req.user.userId}: ${body.action}`);
        return {
            success: true,
            message: 'Activity logged',
        };
    }
};
exports.UsersController = UsersController;
__decorate([
    (0, common_1.Post)('register'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_user_dto_1.CreateUserDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "register", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "getOne", null);
__decorate([
    (0, common_1.Post)('upload-profile-photo'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('profilePhoto', multer_config_1.multerConfig)),
    __param(0, (0, common_1.UploadedFile)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "uploadPhoto", null);
__decorate([
    (0, common_1.Post)('update-location'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updateLocation", null);
__decorate([
    (0, common_1.Post)('activity'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "logActivity", null);
exports.UsersController = UsersController = __decorate([
    (0, common_1.Controller)('api/user'),
    __metadata("design:paramtypes", [users_service_1.UsersService])
], UsersController);
