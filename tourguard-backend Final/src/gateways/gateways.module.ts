import { Module, Global } from '@nestjs/common';
import { SafetyGateway } from './safety.gateway';

@Global()
@Module({
    providers: [SafetyGateway],
    exports: [SafetyGateway],
})
export class GatewaysModule { }
