import { Controller, Post, Body, Get, Param, UseInterceptors, UploadedFile, Request, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { multerConfig } from '../config/multer.config';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('api/users')
export class UsersController {
  constructor(private usersService: UsersService) { }

  @Post('register')
  async register(@Body() dto: CreateUserDto) {
    const created = await this.usersService.create(dto as any);
    delete (created as any).password;
    return created;
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
}
