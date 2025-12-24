"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SOSAlertsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const sos_alert_entity_1 = require("./entities/sos-alert.entity");
let SOSAlertsService = class SOSAlertsService {
    constructor(repo) {
        this.repo = repo;
    }
    async create(userId, dto) {
        const alert = this.repo.create({
            ...dto,
            user: userId ? { id: userId } : null,
            status: sos_alert_entity_1.SOSStatus.PENDING,
        });
        return this.repo.save(alert);
    }
    async findAll() {
        return this.repo.find({
            relations: ['user'],
            order: { triggeredAt: 'DESC' },
        });
    }
    async findPending() {
        return this.repo.find({
            where: { status: sos_alert_entity_1.SOSStatus.PENDING },
            relations: ['user'],
            order: { triggeredAt: 'DESC' },
        });
    }
    async updateStatus(id, status) {
        const alert = await this.repo.findOne({ where: { id } });
        if (alert) {
            alert.status = status;
            if (status === sos_alert_entity_1.SOSStatus.RESOLVED) {
                alert.resolvedAt = new Date();
            }
            return this.repo.save(alert);
        }
        return null;
    }
};
exports.SOSAlertsService = SOSAlertsService;
exports.SOSAlertsService = SOSAlertsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(sos_alert_entity_1.SOSAlert)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], SOSAlertsService);
