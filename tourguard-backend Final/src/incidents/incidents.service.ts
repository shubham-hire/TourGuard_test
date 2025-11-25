import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Incident } from './entities/incident.entity';

@Injectable()
export class IncidentsService {
  constructor(@InjectRepository(Incident) private repo: Repository<Incident>) {}

  async create(dto: Partial<Incident>, userId?: string) {
    const i = this.repo.create({ ...dto });
    return this.repo.save(i);
  }

  async findAll() {
    return this.repo.find();
  }
}
