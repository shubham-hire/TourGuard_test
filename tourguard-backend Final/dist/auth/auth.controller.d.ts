import { AuthService } from './auth.service';
import { OtpService } from '../otp/otp.service';
import { UsersService } from '../users/users.service';
declare class LoginDto {
    email: string;
    password: string;
}
declare class ResetPasswordDto {
    phone: string;
    otp: string;
    newPassword: string;
}
export declare class AuthController {
    private authService;
    private otpService;
    private usersService;
    constructor(authService: AuthService, otpService: OtpService, usersService: UsersService);
    login(dto: LoginDto): Promise<{
        success: boolean;
        message: string;
        data: {
            id: any;
            name: any;
            email: any;
            phone: any;
            hashId: any;
            role: any;
            token: string;
        };
    }>;
    resetPassword(dto: ResetPasswordDto): Promise<{
        success: boolean;
        message: string;
    }>;
}
export {};
