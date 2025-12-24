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
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const auth_service_1 = require("./auth.service");
const class_validator_1 = require("class-validator");
const otp_service_1 = require("../otp/otp.service");
const users_service_1 = require("../users/users.service");
class LoginDto {
}
__decorate([
    (0, class_validator_1.IsEmail)(),
    __metadata("design:type", String)
], LoginDto.prototype, "email", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], LoginDto.prototype, "password", void 0);
class ResetPasswordDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], ResetPasswordDto.prototype, "phone", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], ResetPasswordDto.prototype, "otp", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(6),
    __metadata("design:type", String)
], ResetPasswordDto.prototype, "newPassword", void 0);
let AuthController = class AuthController {
    constructor(authService, otpService, usersService) {
        this.authService = authService;
        this.otpService = otpService;
        this.usersService = usersService;
    }
    async login(dto) {
        const user = await this.authService.validateUser(dto.email, dto.password);
        const authResult = await this.authService.login(user);
        return {
            success: true,
            message: 'Login successful',
            data: {
                id: authResult.user.id,
                name: authResult.user.name || '',
                email: authResult.user.email,
                phone: authResult.user.phone || '',
                hashId: authResult.user.hashId || null,
                role: authResult.user.role,
                token: authResult.access_token,
            },
        };
    }
    async resetPassword(dto) {
        const isValidOtp = this.otpService.verifyOtp(dto.phone, dto.otp);
        if (!isValidOtp) {
            throw new common_1.BadRequestException('Invalid or expired OTP');
        }
        try {
            await this.usersService.updatePassword(dto.phone, dto.newPassword);
            this.otpService.clearOtp(dto.phone);
            return {
                success: true,
                message: 'Password reset successfully',
            };
        }
        catch (error) {
            throw new common_1.BadRequestException('Failed to reset password. User may not exist.');
        }
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('login'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [LoginDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "login", null);
__decorate([
    (0, common_1.Post)('reset-password'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [ResetPasswordDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "resetPassword", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('api/auth'),
    __metadata("design:paramtypes", [auth_service_1.AuthService,
        otp_service_1.OtpService,
        users_service_1.UsersService])
], AuthController);
