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
Object.defineProperty(exports, "__esModule", { value: true });
exports.SOSAlert = exports.SOSStatus = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
var SOSStatus;
(function (SOSStatus) {
    SOSStatus["PENDING"] = "PENDING";
    SOSStatus["ACKNOWLEDGED"] = "ACKNOWLEDGED";
    SOSStatus["RESOLVED"] = "RESOLVED";
})(SOSStatus || (exports.SOSStatus = SOSStatus = {}));
let SOSAlert = class SOSAlert {
};
exports.SOSAlert = SOSAlert;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], SOSAlert.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, { onDelete: 'SET NULL', nullable: true }),
    __metadata("design:type", user_entity_1.User)
], SOSAlert.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 7 }),
    __metadata("design:type", Number)
], SOSAlert.prototype, "latitude", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'decimal', precision: 10, scale: 7 }),
    __metadata("design:type", Number)
], SOSAlert.prototype, "longitude", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], SOSAlert.prototype, "message", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', default: SOSStatus.PENDING }),
    __metadata("design:type", String)
], SOSAlert.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], SOSAlert.prototype, "triggeredAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], SOSAlert.prototype, "resolvedAt", void 0);
exports.SOSAlert = SOSAlert = __decorate([
    (0, typeorm_1.Entity)('sos_alerts')
], SOSAlert);
