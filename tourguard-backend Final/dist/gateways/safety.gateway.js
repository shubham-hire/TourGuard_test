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
exports.SafetyGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
let SafetyGateway = class SafetyGateway {
    handleConnection(client) {
        console.log(`Client connected: ${client.id}`);
    }
    handleDisconnect(client) {
        console.log(`Client disconnected: ${client.id}`);
    }
    handleLocation(data, client) {
        const baseScore = 85;
        const fluctuation = Math.floor(Math.random() * 10) - 5;
        const safetyScore = baseScore + fluctuation;
        client.emit('safety:score', {
            score: safetyScore,
            timestamp: new Date().toISOString(),
            label: safetyScore > 80 ? 'Safe' : 'Caution',
        });
    }
    handleEmergency(client) {
        console.log(`🚨 EMERGENCY TRIGGERED by ${client.id}`);
        client.emit('emergency:ack', {
            status: 'RECEIVED',
            message: 'Emergency alert received. Help is on the way.',
        });
        this.server.emit('admin:alert', {
            source: client.id,
            type: 'SOS',
            timestamp: new Date().toISOString(),
        });
    }
};
exports.SafetyGateway = SafetyGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], SafetyGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('location:update'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", void 0)
], SafetyGateway.prototype, "handleLocation", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('emergency:trigger'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket]),
    __metadata("design:returntype", void 0)
], SafetyGateway.prototype, "handleEmergency", null);
exports.SafetyGateway = SafetyGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: {
            origin: '*',
        },
    })
], SafetyGateway);
