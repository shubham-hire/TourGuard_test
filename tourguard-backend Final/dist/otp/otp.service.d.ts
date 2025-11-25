export declare class OtpService {
    private otpStore;
    generateOtp(phone: string): string;
    verifyOtp(phone: string, otp: string): boolean;
    clearOtp(phone: string): void;
}
