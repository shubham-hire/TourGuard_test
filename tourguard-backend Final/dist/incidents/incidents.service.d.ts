import { Repository } from 'typeorm';
import { Incident } from './entities/incident.entity';
export declare class IncidentsService {
    private repo;
    constructor(repo: Repository<Incident>);
    create(dto: Partial<Incident>, userId?: string): Promise<Incident>;
    findAll(): Promise<Incident[]>;
}
