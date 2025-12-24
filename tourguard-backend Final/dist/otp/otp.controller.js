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
exports.OtpController = void 0;
const common_1 = require("@nestjs/common");
const otp_service_1 = require("./otp.service");
const users_service_1 = require("../users/users.service");
let OtpController = class OtpController {
    constructor(otpService, usersService) {
        this.otpService = otpService;
        this.usersService = usersService;
    }
    async sendOtp(body) {
        const { phone } = body;
        if (!phone) {
            throw new common_1.HttpException('Phone number is required', common_1.HttpStatus.BAD_REQUEST);
        }
        const otp = this.otpService.generateOtp(phone);
        console.log(`📱 OTP for ${phone}: ${otp}`);
        return {
            success: true,
            message: 'OTP sent successfully',
            data: { otp },
        };
    }
    async verifyOtp(body) {
        const { phone, otp } = body;
        if (!phone || !otp) {
            throw new common_1.HttpException('Phone number and OTP are required', common_1.HttpStatus.BAD_REQUEST);
        }
        const isValid = this.otpService.verifyOtp(phone, otp);
        if (!isValid) {
            throw new common_1.HttpException('Invalid or expired OTP', common_1.HttpStatus.UNAUTHORIZED);
        }
        const user = await this.usersService.findByPhone(phone);
        if (!user) {
            throw new common_1.HttpException('User not found', common_1.HttpStatus.NOT_FOUND);
        }
        const updatedUser = await this.usersService.setHashIdAfterOtp(user.id);
        this.otpService.clearOtp(phone);
        const token = await this.usersService.generateToken(updatedUser);
        return {
            success: true,
            message: 'OTP verified successfully',
            data: {
                id: updatedUser.id,
                hashId: updatedUser.hashId,
                name: updatedUser.name,
                email: updatedUser.email,
                phone: updatedUser.phone,
                token,
            },
        };
    }
};
exports.OtpController = OtpController;
__decorate([
    (0, common_1.Post)('send'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OtpController.prototype, "sendOtp", null);
__decorate([
    (0, common_1.Post)('verify'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OtpController.prototype, "verifyOtp", null);
exports.OtpController = OtpController = __decorate([
    (0, common_1.Controller)('api/otp'),
    __metadata("design:paramtypes", [otp_service_1.OtpService,
        users_service_1.UsersService])
], OtpController);
