import { ToursService } from './tours.service';
export declare class ToursController {
    private toursService;
    constructor(toursService: ToursService);
    create(dto: any, req: any): Promise<import("./entities/tour.entity").Tour>;
    findAll(): Promise<import("./entities/tour.entity").Tour[]>;
}
