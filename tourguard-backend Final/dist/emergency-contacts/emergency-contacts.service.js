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
exports.EmergencyContactsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const emergency_contact_entity_1 = require("./entities/emergency-contact.entity");
let EmergencyContactsService = class EmergencyContactsService {
    constructor(repo) {
        this.repo = repo;
    }
    async create(userId, dto) {
        var _a;
        const contact = this.repo.create({
            name: dto.name,
            phone: dto.phone,
            relationship: dto.relationship,
            isPrimary: (_a = dto.isPrimary) !== null && _a !== void 0 ? _a : false,
            userId: userId,
            user: null,
        });
        return this.repo.save(contact);
    }
    async findByUser(userId) {
        return this.repo.find({
            where: { userId: userId },
            order: { isPrimary: 'DESC', createdAt: 'ASC' },
        });
    }
    async findAll() {
        return this.repo.find({
            order: { createdAt: 'DESC' },
        });
    }
    async delete(id, userId) {
        const contact = await this.repo.findOne({
            where: { id, userId: userId },
        });
        if (contact) {
            await this.repo.remove(contact);
            return { deleted: true };
        }
        return { deleted: false };
    }
};
exports.EmergencyContactsService = EmergencyContactsService;
exports.EmergencyContactsService = EmergencyContactsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(emergency_contact_entity_1.EmergencyContact)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], EmergencyContactsService);
