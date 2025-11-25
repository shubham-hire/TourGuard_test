import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tour } from './entities/tour.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class ToursService {
  constructor(@InjectRepository(Tour) private toursRepo: Repository<Tour>) {}

  async create(dto: Partial<Tour>, userId?: string) {
    const t = this.toursRepo.create({ ...dto });
    return this.toursRepo.save(t);
  }

  async findAll() {
    return this.toursRepo.find();
  }
}
