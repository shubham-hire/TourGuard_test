import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Incident } from './entities/incident.entity';
import { SafetyGateway } from '../gateways/safety.gateway';

@Injectable()
export class IncidentsService {
  constructor(
    @InjectRepository(Incident) private repo: Repository<Incident>,
    private gateway: SafetyGateway,
  ) {}

  async create(dto: Partial<Incident>, userId?: string) {
    const i = this.repo.create({ ...dto });
    const saved = await this.repo.save(i);

    // Broadcast to all connected admin clients via WebSocket
    this.gateway.server.emit('admin:incident', {
      type: 'NEW_INCIDENT',
      incidentId: saved.id,
      severity: saved.severity,
      title: saved.title,
      timestamp: new Date().toISOString(),
    });

    console.log('📋 Incident created and broadcasted:', saved.id);
    return saved;
  }

  async findAll() {
    return this.repo.find();
  }
}

