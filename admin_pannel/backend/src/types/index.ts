/**
 * TypeScript type definitions for the application
 */

export interface User {
    id: string;
    name: string;
    phone: string;
    email: string;
    passwordHash?: string;
    password_hash?: string;
    externalId?: string;
    role: 'user' | 'admin';
    medicalConditions?: string;
    allergies?: string;
    emergencyContacts?: EmergencyContact[];
    createdAt: Date;
    updatedAt: Date;
}

export interface EmergencyContact {
    name: string;
    relation: string;
    phone: string;
}

export interface SosEvent {
    id: string;
    userId: string;
    latitude: number;
    longitude: number;
    accuracyMeters?: number;
    message?: string;
    status: 'pending' | 'acknowledged' | 'resolved';
    createdAt: Date;
    acknowledgedAt?: Date;
    resolvedAt?: Date;
    user?: User; // Populated in queries
}

export interface AuditLog {
    id: string;
    eventType: string;
    userId?: string;
    sosEventId?: string;
    payload: Record<string, any>;
    createdAt: Date;
}

export interface JwtPayload {
    userId: string;
    email: string;
    role: 'user' | 'admin';
}

export interface ApiResponse<T = any> {
    success: boolean;
    data?: T;
    error?: string;
    message?: string;
}
