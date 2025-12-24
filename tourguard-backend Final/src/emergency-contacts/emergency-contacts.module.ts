import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EmergencyContact } from './entities/emergency-contact.entity';
import { EmergencyContactsService } from './emergency-contacts.service';
import { EmergencyContactsController } from './emergency-contacts.controller';

@Module({
    imports: [TypeOrmModule.forFeature([EmergencyContact])],
    providers: [EmergencyContactsService],
    controllers: [EmergencyContactsController],
    exports: [EmergencyContactsService],
})
export class EmergencyContactsModule { }
