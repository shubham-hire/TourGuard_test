import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UsersService } from './users/users.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const usersService = app.get(UsersService);
  const admin = await usersService.findByEmail('admin@tourguard.local');
  if (!admin) {
    await usersService.create({ email: 'admin@tourguard.local', password: 'Admin123!', name: 'Admin', role: 'ADMIN' } as any);
    console.log('Admin created');
  } else {
    console.log('Admin already exists');
  }
  await app.close();
}
bootstrap();
