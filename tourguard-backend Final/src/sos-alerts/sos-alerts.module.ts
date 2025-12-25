import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SOSAlert } from './entities/sos-alert.entity';
import { SOSAlertsService } from './sos-alerts.service';
import { SOSAlertsController } from './sos-alerts.controller';

@Module({
    imports: [TypeOrmModule.forFeature([SOSAlert])],
    providers: [SOSAlertsService],
    controllers: [SOSAlertsController],
    exports: [SOSAlertsService],
})
export class SOSAlertsModule { }