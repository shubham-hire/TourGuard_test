import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { IsEmail, IsString } from 'class-validator';

class LoginDto {
  @IsEmail() email: string;
  @IsString() password: string;
}

@Controller('api/auth')
export class AuthController {
  constructor(private authService: AuthService) {}

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
}
