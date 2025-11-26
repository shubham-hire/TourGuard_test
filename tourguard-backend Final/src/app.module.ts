import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import configuration from './config/configuration';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { ToursModule } from './tours/tours.module';
import { IncidentsModule } from './incidents/incidents.module';
import { OtpModule } from './otp/otp.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    TypeOrmModule.forRootAsync({
      useFactory: (config: ConfigService) => ({
        type: 'sqlite',
        database: 'database.sqlite',
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: true, // Enable for dev to auto-create tables
      }),
      inject: [ConfigService],
    }),
    UsersModule,
    AuthModule,
    ToursModule,
    IncidentsModule,
    OtpModule,
  ],
})
export class AppModule { }
