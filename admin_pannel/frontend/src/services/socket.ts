/**
 * Socket.IO client for real-time SOS updates
 */

import { io, Socket } from 'socket.io-client';
import { SosEvent } from '../types';

// Use same base URL as API (Render backend)
const SOCKET_URL = import.meta.env.VITE_API_BASE_URL || 'https://tourguard-test.onrender.com';

let socket: Socket | null = null;

const getAuthToken = () => localStorage.getItem('token');

export const initializeSocket = (): Socket | null => {
    const token = getAuthToken();

    // Don't require token - socket can still receive broadcasts
    if (socket?.connected) {
        return socket;
    }

    if (!socket) {
        socket = io(SOCKET_URL, {
            transports: ['websocket', 'polling'], // Allow fallback to polling
            reconnection: true,
            reconnectionAttempts: 10,
            reconnectionDelay: 2000,
            auth: token ? { token } : {},
        });

        socket.on('connect', () => {
            console.log('✓ Admin Socket.IO connected to', SOCKET_URL);
        });

        socket.on('disconnect', () => {
            console.log('✗ Socket.IO disconnected');
        });

        socket.on('connect_error', (error) => {
            console.error('Socket.IO connection error:', error);
            if ((error as Error)?.message === 'Unauthorized') {
                localStorage.removeItem('token');
                localStorage.removeItem('user');
                window.location.href = '/login';
            }
        });
    }

    return socket;
};

export const disconnectSocket = () => {
    if (socket) {
        socket.disconnect();
        socket = null;
    }
};

export const onSosNew = (callback: (event: SosEvent) => void) => {
    if (socket) {
        socket.on('sos:new', callback);
    }
};

export const onSosUpdate = (callback: (event: SosEvent) => void) => {
    if (socket) {
        socket.on('sos:update', callback);
    }
};

// Listen for admin:alert events from backend (emitted on SOS trigger)
export const onAdminAlert = (callback: (data: { source: string; type: string; timestamp: string }) => void) => {
    if (socket) {
        socket.on('admin:alert', (data) => {
            console.log('🚨 Received admin:alert:', data);
            callback(data);
        });
    }
};

export const offSosNew = () => {
    if (socket) {
        socket.off('sos:new');
    }
};

export const offSosUpdate = () => {
    if (socket) {
        socket.off('sos:update');
    }
};

export const offAdminAlert = () => {
    if (socket) {
        socket.off('admin:alert');
    }
};

// Listen for admin:incident events from backend (emitted on incident creation)
export const onAdminIncident = (callback: (data: { type: string; incidentId: string; severity: string; title: string; timestamp: string }) => void) => {
    if (socket) {
        socket.on('admin:incident', (data) => {
            console.log('📋 Received admin:incident:', data);
            callback(data);
        });
    }
};

export const offAdminIncident = () => {
    if (socket) {
        socket.off('admin:incident');
    }
};

export default {
    initializeSocket,
    disconnectSocket,
    onSosNew,
    onSosUpdate,
    onAdminAlert,
    onAdminIncident,
    offSosNew,
    offSosUpdate,
    offAdminAlert,
    offAdminIncident,
};
