import { OtpService } from './otp.service';
import { UsersService } from '../users/users.service';
export declare class OtpController {
    private otpService;
    private usersService;
    constructor(otpService: OtpService, usersService: UsersService);
    sendOtp(body: {
        phone: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: {
            otp: string;
        };
    }>;
    verifyOtp(body: {
        phone: string;
        otp: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: {
            id: string;
            hashId: string;
            name: string;
            email: string;
            phone: string;
            token: string;
        };
    }>;
}
