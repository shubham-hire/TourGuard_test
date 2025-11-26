/**
 * Socket.IO server setup and event emission
 * Manages WebSocket connections for real-time SOS updates
 */

import { Server as HttpServer } from 'http';
import { Server as SocketIOServer, Namespace, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { JwtPayload } from '../types';

let io: SocketIOServer;
let adminNamespace: Namespace;

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

/**
 * Initialize Socket.IO server
 */
export const initializeSocket = (httpServer: HttpServer) => {
    io = new SocketIOServer(httpServer, {
        cors: {
            origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
            credentials: true,
        },
    });

    adminNamespace = io.of('/admin');

    adminNamespace.use((socket: Socket, next) => {
        try {
            const token =
                socket.handshake.auth?.token ||
                (socket.handshake.headers.authorization || '').toString().replace('Bearer ', '');

            if (!token) {
                return next(new Error('Unauthorized: missing token'));
            }

            const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
            socket.data.user = decoded;
            return next();
        } catch (error) {
            console.warn(`[socket] Unauthorized connection attempt: ${error}`);
            return next(new Error('Unauthorized'));
        }
    });

    adminNamespace.on('connection', (socket) => {
        console.log(`Admin client connected: ${socket.id} (user=${socket.data.user?.email})`);

        socket.on('disconnect', () => {
            console.log(`Admin client disconnected: ${socket.id}`);
        });
    });

    return io;
};

/**
 * Emit SOS event to all connected admin clients
 */
export const emitSosEvent = (event: string, data: any) => {
    if (adminNamespace) {
        adminNamespace.emit(event, data);
        console.log(`Emitted ${event}:`, data.id);
    }
};

export default { initializeSocket, emitSosEvent };
