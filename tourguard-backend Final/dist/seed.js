"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const users_service_1 = require("./users/users.service");
async function bootstrap() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule);
    const usersService = app.get(users_service_1.UsersService);
    const admin = await usersService.findByEmail('admin@tourguard.local');
    if (!admin) {
        await usersService.create({ email: 'admin@tourguard.local', password: 'Admin123!', name: 'Admin', role: 'ADMIN' });
        console.log('Admin created');
    }
    else {
        console.log('Admin already exists');
    }
    await app.close();
}
bootstrap();
