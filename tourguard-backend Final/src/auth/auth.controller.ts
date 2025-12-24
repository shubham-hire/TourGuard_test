import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { IsEmail, IsString, MinLength, IsOptional } from 'class-validator';
import { OtpService } from '../otp/otp.service';
import { UsersService } from '../users/users.service';

class LoginDto {
  @IsEmail() email: string;
  @IsString() password: string;
}

class ResetPasswordDto {
  @IsString() phone: string;
  @IsString() otp: string;
  @IsString() @MinLength(6) newPassword: string;
}

@Controller('api/auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private otpService: OtpService,
    private usersService: UsersService,
  ) { }

  @Post('login')
  async login(@Body() dto: LoginDto) {
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

  @Post('reset-password')
  async resetPassword(@Body() dto: ResetPasswordDto) {
    // Verify OTP
    const isValidOtp = this.otpService.verifyOtp(dto.phone, dto.otp);
    if (!isValidOtp) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    // Update password
    try {
      await this.usersService.updatePassword(dto.phone, dto.newPassword);

      // Clear used OTP
      this.otpService.clearOtp(dto.phone);

      return {
        success: true,
        message: 'Password reset successfully',
      };
    } catch (error) {
      throw new BadRequestException('Failed to reset password. User may not exist.');
    }
  }
}
