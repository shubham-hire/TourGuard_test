"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const app_module_1 = require("./app.module");
const config_1 = require("@nestjs/config");
const path_1 = require("path");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.enableCors();
    app.useStaticAssets((0, path_1.join)(__dirname, '..', 'uploads'), {
        prefix: '/uploads/',
    });
    app.useGlobalPipes(new common_1.ValidationPipe({ whitelist: true, forbidNonWhitelisted: false }));
    const config = app.get(config_1.ConfigService);
    const port = config.get('PORT') || 3000;
    await app.listen(port);
    console.log(`\n🚀 TourGuard Backend (NestJS) Running`);
    console.log(`📍 Port: ${port}`);
    console.log(`🌐 Health: http://localhost:${port}/api/health`);
    console.log(`⏰ Started at: ${new Date().toLocaleString()}\n`);
}
bootstrap();
