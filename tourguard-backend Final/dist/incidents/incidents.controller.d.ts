import { IncidentsService } from './incidents.service';
export declare class IncidentsController {
    private incidentsService;
    constructor(incidentsService: IncidentsService);
    report(dto: any): Promise<import("./entities/incident.entity").Incident>;
    list(): Promise<import("./entities/incident.entity").Incident[]>;
}
