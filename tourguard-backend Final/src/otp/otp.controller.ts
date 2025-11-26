import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { OtpService } from './otp.service';
import { UsersService } from '../users/users.service';

@Controller('api/otp')
export class OtpController {
    constructor(
        private otpService: OtpService,
        private usersService: UsersService,
    ) { }

    @Post('send')
    async sendOtp(@Body() body: { phone: string }) {
        const { phone } = body;

        if (!phone) {
            throw new HttpException('Phone number is required', HttpStatus.BAD_REQUEST);
        }

        // Generate and store OTP (works for both existing and new users)
        const otp = this.otpService.generateOtp(phone);

        // In production, send SMS here
        console.log(`📱 OTP for ${phone}: ${otp}`);

        return {
            success: true,
            message: 'OTP sent successfully',
            // Include OTP in response for development (remove in production)
            data: { otp },
        };
    }

    @Post('verify')
    async verifyOtp(@Body() body: { phone: string; otp: string }) {
        const { phone, otp } = body;

        if (!phone || !otp) {
            throw new HttpException('Phone number and OTP are required', HttpStatus.BAD_REQUEST);
        }

        // Verify OTP
        const isValid = this.otpService.verifyOtp(phone, otp);
        if (!isValid) {
            throw new HttpException('Invalid or expired OTP', HttpStatus.UNAUTHORIZED);
        }

        // Get user and generate hash ID
        const user = await this.usersService.findByPhone(phone);
        if (!user) {
            throw new HttpException('User not found', HttpStatus.NOT_FOUND);
        }

        // Generate hash ID and mark as verified
        const updatedUser = await this.usersService.setHashIdAfterOtp(user.id);

        // Clear OTP from storage
        this.otpService.clearOtp(phone);

        // Generate JWT token
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
}
