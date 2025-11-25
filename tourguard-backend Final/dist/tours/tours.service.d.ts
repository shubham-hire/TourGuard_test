import { Repository } from 'typeorm';
import { Tour } from './entities/tour.entity';
export declare class ToursService {
    private toursRepo;
    constructor(toursRepo: Repository<Tour>);
    create(dto: Partial<Tour>, userId?: string): Promise<Tour>;
    findAll(): Promise<Tour[]>;
}
