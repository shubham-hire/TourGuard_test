import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import configuration from './config/configuration';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { ToursModule } from './tours/tours.module';
import { IncidentsModule } from './incidents/incidents.module';
import { OtpModule } from './otp/otp.module';
import { EmergencyContactsModule } from './emergency-contacts/emergency-contacts.module';
import { SOSAlertsModule } from './sos-alerts/sos-alerts.module';
import { ChatModule } from './chat/chat.module';
import { HealthController } from './health.controller';
import { GatewaysModule } from './gateways/gateways.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    TypeOrmModule.forRootAsync({
      useFactory: (config: ConfigService) => {
        const databaseUrl = process.env.DATABASE_URL;

        if (databaseUrl) {
          // PostgreSQL on Render (production)
          return {
            type: 'postgres',
            url: databaseUrl,
            entities: [__dirname + '/**/*.entity{.ts,.js}'],
            synchronize: true, // Auto-create tables (safe for dev/hackathon)
            ssl: { rejectUnauthorized: false }, // Required for Render PostgreSQL
          };
        } else {
          // SQLite for local development
          return {
            type: 'sqlite',
            database: 'database.sqlite',
            entities: [__dirname + '/**/*.entity{.ts,.js}'],
            synchronize: true,
          };
        }
      },
      inject: [ConfigService],
    }),
    UsersModule,
    AuthModule,
    ToursModule,
    IncidentsModule,
    OtpModule,
    EmergencyContactsModule,
    SOSAlertsModule,
    ChatModule,
    GatewaysModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule { }

