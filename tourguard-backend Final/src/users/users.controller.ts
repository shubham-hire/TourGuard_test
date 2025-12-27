import { Controller, Post, Body, Get, Param, UseInterceptors, UploadedFile, Request, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { multerConfig } from '../config/multer.config';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/user')
export class UsersController {
  constructor(private usersService: UsersService) { }

  @Post('register')
  async register(@Body() dto: CreateUserDto) {
    // Check if user already exists
    const existingUser = await this.usersService.findByPhone(dto.phone) ||
      await this.usersService.findByEmail(dto.email);

    if (existingUser) {
      throw new HttpException('User already exists with this email or phone', HttpStatus.CONFLICT);
    }

    const created = await this.usersService.create(dto as any);
    const token = await this.usersService.generateToken(created);

    return {
      success: true,
      message: 'Registration successful',
      data: {
        id: created.id,
        name: created.name,
        email: created.email,
        phone: created.phone,
        token,
      },
    };
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    const u = await this.usersService.findById(id);
    delete (u as any).password;
    return u;
  }

  @Post('upload-profile-photo')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('profilePhoto', multerConfig))
  async uploadPhoto(
    @UploadedFile() file: Express.Multer.File,
    @Request() req,
  ) {
    if (!file) {
      throw new HttpException('No photo file provided', HttpStatus.BAD_REQUEST);
    }

    const photoUrl = `/uploads/profile-photos/${file.filename}`;
    await this.usersService.uploadProfilePhoto(req.user.userId, photoUrl);

    return {
      success: true,
      message: 'Profile photo uploaded successfully',
      data: { photoUrl },
    };
  }

  // Location update endpoint (for backward compatibility with REST calls)
  @Post('update-location')
  @UseGuards(JwtAuthGuard)
  async updateLocation(
    @Body() body: { lat: number; lng: number },
    @Request() req,
  ) {
    // Just acknowledge - real-time updates now handled via WebSocket
    console.log(`Location update from user ${req.user.userId}: ${body.lat}, ${body.lng}`);
    return {
      success: true,
      message: 'Location received',
    };
  }

  // Activity logging endpoint
  @Post('activity')
  @UseGuards(JwtAuthGuard)
  async logActivity(
    @Body() body: { action: string; metadata?: any },
    @Request() req,
  ) {
    // Just acknowledge - could store in DB if needed later
    console.log(`Activity from user ${req.user.userId}: ${body.action}`);
    return {
      success: true,
      message: 'Activity logged',
    };
  }
}
