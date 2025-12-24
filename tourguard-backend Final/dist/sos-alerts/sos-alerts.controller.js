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
exports.SOSAlertsController = void 0;
const common_1 = require("@nestjs/common");
const sos_alerts_service_1 = require("./sos-alerts.service");
let SOSAlertsController = class SOSAlertsController {
    constructor(service) {
        this.service = service;
    }
    create(dto) {
        return this.service.create(dto.userId || null, dto);
    }
    findAll() {
        return this.service.findAll();
    }
    findPending() {
        return this.service.findPending();
    }
    updateStatus(id, dto) {
        return this.service.updateStatus(id, dto.status);
    }
};
exports.SOSAlertsController = SOSAlertsController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], SOSAlertsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SOSAlertsController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('pending'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SOSAlertsController.prototype, "findPending", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], SOSAlertsController.prototype, "updateStatus", null);
exports.SOSAlertsController = SOSAlertsController = __decorate([
    (0, common_1.Controller)('api/sos-alerts'),
    __metadata("design:paramtypes", [sos_alerts_service_1.SOSAlertsService])
], SOSAlertsController);
