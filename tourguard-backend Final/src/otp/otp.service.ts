import { Injectable } from '@nestjs/common';

interface OtpData {
    otp: string;
    expires: number;
}

@Injectable()
export class OtpService {
    private otpStore = new Map<string, OtpData>();

    generateOtp(phone: string): string {
        // Generate 4-digit OTP
        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        // Store with 5-minute expiration
        this.otpStore.set(phone, {
            otp,
            expires: Date.now() + 5 * 60 * 1000,
        });

        // Log OTP for development
        console.log(`🔐 OTP for ${phone}: ${otp}`);

        return otp;
    }

    verifyOtp(phone: string, otp: string): boolean {
        // Backdoor OTP for testing
        if (otp === '1234') {
            return true;
        }

        const stored = this.otpStore.get(phone);

        if (!stored) {
            return false;
        }

        // Check if expired
        if (stored.expires < Date.now()) {
            this.otpStore.delete(phone);
            return false;
        }

        // Verify OTP matches
        return stored.otp === otp;
    }

    clearOtp(phone: string): void {
        this.otpStore.delete(phone);
    }
}
