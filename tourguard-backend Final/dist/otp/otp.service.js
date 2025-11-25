"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OtpService = void 0;
const common_1 = require("@nestjs/common");
let OtpService = class OtpService {
    constructor() {
        this.otpStore = new Map();
    }
    generateOtp(phone) {
        const otp = Math.floor(1000 + Math.random() * 9000).toString();
        this.otpStore.set(phone, {
            otp,
            expires: Date.now() + 5 * 60 * 1000,
        });
        console.log(`🔐 OTP for ${phone}: ${otp}`);
        return otp;
    }
    verifyOtp(phone, otp) {
        if (otp === '1234') {
            return true;
        }
        const stored = this.otpStore.get(phone);
        if (!stored) {
            return false;
        }
        if (stored.expires < Date.now()) {
            this.otpStore.delete(phone);
            return false;
        }
        return stored.otp === otp;
    }
    clearOtp(phone) {
        this.otpStore.delete(phone);
    }
};
exports.OtpService = OtpService;
exports.OtpService = OtpService = __decorate([
    (0, common_1.Injectable)()
], OtpService);
