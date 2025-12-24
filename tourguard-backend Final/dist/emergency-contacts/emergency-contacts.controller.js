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
exports.EmergencyContactsController = void 0;
const common_1 = require("@nestjs/common");
const emergency_contacts_service_1 = require("./emergency-contacts.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let EmergencyContactsController = class EmergencyContactsController {
    constructor(service) {
        this.service = service;
    }
    create(dto) {
        const userId = dto.userId || 'anonymous';
        return this.service.create(userId, dto);
    }
    findAll(req) {
        return this.service.findByUser(req.user.id);
    }
    findAllContacts() {
        return this.service.findAll();
    }
    delete(id, req) {
        return this.service.delete(id, req.user.id);
    }
};
exports.EmergencyContactsController = EmergencyContactsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], EmergencyContactsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], EmergencyContactsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('all'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], EmergencyContactsController.prototype, "findAllContacts", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], EmergencyContactsController.prototype, "delete", null);
exports.EmergencyContactsController = EmergencyContactsController = __decorate([
    (0, common_1.Controller)('api/emergency-contacts'),
    __metadata("design:paramtypes", [emergency_contacts_service_1.EmergencyContactsService])
], EmergencyContactsController);
