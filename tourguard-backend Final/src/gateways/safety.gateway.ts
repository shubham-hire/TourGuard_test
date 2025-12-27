import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    OnGatewayConnection,
    OnGatewayDisconnect,
    MessageBody,
    ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
    cors: {
        origin: '*', // Allow all origins for hackathon (simplified)
    },
})
export class SafetyGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server: Server;

    handleConnection(client: Socket) {
        console.log(`Client connected: ${client.id}`);
    }

    handleDisconnect(client: Socket) {
        console.log(`Client disconnected: ${client.id}`);
    }

    @SubscribeMessage('location:update')
    handleLocation(
        @MessageBody() data: { lat: number; lng: number },
        @ConnectedSocket() client: Socket,
    ) {
        // 1. Log received location
        // console.log(`Received location from ${client.id}:`, data);

        // 2. Calculate mock safety score (0-100)
        // In a real app, this would call SafetyService, check database, etc.
        // For now, we simulate "calculation" based on random factors or simple logic
        // to prove the real-time loop works.

        // safe = high score, unsafe = low score
        // Mock logic: randomly fluctuate slightly around a high score to show "live" data
        const baseScore = 85;
        const fluctuation = Math.floor(Math.random() * 10) - 5; // -5 to +5
        const safetyScore = baseScore + fluctuation;

        // 3. Emit back to the specific client immediately (<100ms latency)
        client.emit('safety:score', {
            score: safetyScore,
            timestamp: new Date().toISOString(),
            label: safetyScore > 80 ? 'Safe' : 'Caution',
        });
    }

    @SubscribeMessage('emergency:trigger')
    handleEmergency(@ConnectedSocket() client: Socket) {
        console.log(`🚨 EMERGENCY TRIGGERED by ${client.id}`);

        // Ack immediately
        client.emit('emergency:ack', {
            status: 'RECEIVED',
            message: 'Emergency alert received. Help is on the way.',
        });

        // Broadcast to "admin" room or just log for now
        this.server.emit('admin:alert', {
            source: client.id,
            type: 'SOS',
            timestamp: new Date().toISOString(),
        });
    }
}
