"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const configuration_1 = require("./config/configuration");
const typeorm_1 = require("@nestjs/typeorm");
const users_module_1 = require("./users/users.module");
const auth_module_1 = require("./auth/auth.module");
const tours_module_1 = require("./tours/tours.module");
const incidents_module_1 = require("./incidents/incidents.module");
const otp_module_1 = require("./otp/otp.module");
const emergency_contacts_module_1 = require("./emergency-contacts/emergency-contacts.module");
const sos_alerts_module_1 = require("./sos-alerts/sos-alerts.module");
const health_controller_1 = require("./health.controller");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true, load: [configuration_1.default] }),
            typeorm_1.TypeOrmModule.forRootAsync({
                useFactory: (config) => {
                    const databaseUrl = process.env.DATABASE_URL;
                    if (databaseUrl) {
                        return {
                            type: 'postgres',
                            url: databaseUrl,
                            entities: [__dirname + '/**/*.entity{.ts,.js}'],
                            synchronize: true,
                            ssl: { rejectUnauthorized: false },
                        };
                    }
                    else {
                        return {
                            type: 'sqlite',
                            database: 'database.sqlite',
                            entities: [__dirname + '/**/*.entity{.ts,.js}'],
                            synchronize: true,
                        };
                    }
                },
                inject: [config_1.ConfigService],
            }),
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
            tours_module_1.ToursModule,
            incidents_module_1.IncidentsModule,
            otp_module_1.OtpModule,
            emergency_contacts_module_1.EmergencyContactsModule,
            sos_alerts_module_1.SOSAlertsModule,
        ],
        controllers: [health_controller_1.HealthController],
    })
], AppModule);
