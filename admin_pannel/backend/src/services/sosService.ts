/**
 * SOS service layer
 * Contains business logic for SOS events, audit logging, and Socket.IO emissions
 */

import bcrypt from 'bcrypt';
import pool from '../config/database';
import { EmergencyContact, SosEvent, User } from '../types';
import { emitSosEvent } from '../socket';

interface ExternalUserPayload {
    externalId: string;
    name?: string;
    phone?: string;
    email?: string;
    medicalConditions?: string;
    allergies?: string;
    emergencyContacts?: EmergencyContact[];
}

interface CreateSosEventParams {
    userId?: string;
    externalUser?: ExternalUserPayload;
    latitude: number;
    longitude: number;
    accuracyMeters?: number;
    message?: string;
    timestamp?: string;
}

interface ListSosEventsParams {
    status?: string;
    since?: string;
}

const EXTERNAL_USER_PASSWORD = process.env.EXTERNAL_USER_PASSWORD || 'tourguard-external-sync-user';

const contactsToJson = (contacts?: EmergencyContact[]) =>
    contacts && contacts.length ? JSON.stringify(contacts) : null;

const upsertUserByExternalId = async (payload: ExternalUserPayload): Promise<User> => {
    const existing = await pool.query<User>('SELECT * FROM users WHERE external_id = $1', [payload.externalId]);

    if (existing.rows.length > 0) {
        const existingUser = existing.rows[0] as any;
        const updateResult = await pool.query<User>(
            `UPDATE users
         SET name = COALESCE($2, name),
             phone = COALESCE($3, phone),
             email = COALESCE($4, email),
             medical_conditions = COALESCE($5, medical_conditions),
             allergies = COALESCE($6, allergies),
             emergency_contacts = COALESCE($7, emergency_contacts),
             updated_at = NOW()
         WHERE external_id = $1
         RETURNING *`,
            [
                payload.externalId,
                payload.name || existingUser.name,
                payload.phone || existingUser.phone,
                payload.email || existingUser.email,
                payload.medicalConditions ?? existingUser.medical_conditions,
                payload.allergies ?? existingUser.allergies,
                payload.emergencyContacts ? contactsToJson(payload.emergencyContacts) : existingUser.emergency_contacts,
            ]
        );
        return updateResult.rows[0];
    }

    const passwordHash = await bcrypt.hash(EXTERNAL_USER_PASSWORD, 10);

    const insertResult = await pool.query<User>(
        `INSERT INTO users
        (name, phone, email, password_hash, role, medical_conditions, allergies, emergency_contacts, external_id)
     VALUES ($1, $2, $3, $4, 'user', $5, $6, $7, $8)
     RETURNING *`,
        [
            payload.name || 'TourGuard User',
            payload.phone || `ext-${payload.externalId}`,
            payload.email || `${payload.externalId}@tourguard.local`,
            passwordHash,
            payload.medicalConditions || null,
            payload.allergies || null,
            contactsToJson(payload.emergencyContacts),
            payload.externalId,
        ]
    );

    return insertResult.rows[0];
};

const resolveUserRecord = async (params: CreateSosEventParams): Promise<any> => {
    if (params.userId) {
        const userResult = await pool.query<User>('SELECT * FROM users WHERE id = $1', [params.userId]);
        if (userResult.rows.length === 0) {
            throw new Error('User not found for provided userId');
        }
        return userResult.rows[0];
    }

    if (params.externalUser) {
        return upsertUserByExternalId(params.externalUser);
    }

    throw new Error('Either userId or externalUser payload is required');
};

/**
 * List SOS events with optional filtering
 */
export const listSosEvents = async (params: ListSosEventsParams) => {
    let query = `
    SELECT 
      se.id, se.user_id, se.latitude, se.longitude, se.accuracy_meters,
      se.message, se.status, se.created_at, se.acknowledged_at, se.resolved_at,
      u.name as user_name, u.phone as user_phone, u.email as user_email,
      u.medical_conditions, u.allergies
    FROM sos_events se
    JOIN users u ON se.user_id = u.id
    WHERE 1=1
  `;

    const queryParams: any[] = [];
    let paramIndex = 1;

    if (params.status) {
        query += ` AND se.status = $${paramIndex}`;
        queryParams.push(params.status);
        paramIndex++;
    }

    if (params.since) {
        query += ` AND se.created_at >= $${paramIndex}`;
        queryParams.push(params.since);
        paramIndex++;
    }

    query += ' ORDER BY se.created_at DESC';

    const result = await pool.query(query, queryParams);

    return result.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        accuracyMeters: row.accuracy_meters,
        message: row.message,
        status: row.status,
        createdAt: row.created_at,
        acknowledgedAt: row.acknowledged_at,
        resolvedAt: row.resolved_at,
        user: {
            name: row.user_name,
            phone: row.user_phone,
            email: row.user_email,
            medicalConditions: row.medical_conditions,
            allergies: row.allergies,
        },
    }));
};

/**
 * Get single SOS event by ID
 */
export const getSosEventById = async (id: string) => {
    const result = await pool.query(
        `SELECT 
      se.id, se.user_id, se.latitude, se.longitude, se.accuracy_meters,
      se.message, se.status, se.created_at, se.acknowledged_at, se.resolved_at,
      u.name as user_name, u.phone as user_phone, u.email as user_email,
      u.medical_conditions, u.allergies, u.emergency_contacts
    FROM sos_events se
    JOIN users u ON se.user_id = u.id
    WHERE se.id = $1`,
        [id]
    );

    if (result.rows.length === 0) {
        return null;
    }

    const row = result.rows[0];

    return {
        id: row.id,
        userId: row.user_id,
        latitude: parseFloat(row.latitude),
        longitude: parseFloat(row.longitude),
        accuracyMeters: row.accuracy_meters,
        message: row.message,
        status: row.status,
        createdAt: row.created_at,
        acknowledgedAt: row.acknowledged_at,
        resolvedAt: row.resolved_at,
        user: {
            name: row.user_name,
            phone: row.user_phone,
            email: row.user_email,
            medicalConditions: row.medical_conditions,
            allergies: row.allergies,
            emergencyContacts: row.emergency_contacts,
        },
    };
};

/**
 * Create new SOS event and emit to connected admins
 */
export const createSosEvent = async (params: CreateSosEventParams) => {
    const userRecord = await resolveUserRecord(params);
    const resolvedUserId = params.userId || userRecord.id;

    const result = await pool.query(
        `INSERT INTO sos_events 
      (user_id, latitude, longitude, accuracy_meters, message, status, created_at)
    VALUES ($1, $2, $3, $4, $5, 'pending', COALESCE($6::timestamp, NOW()))
    RETURNING *`,
        [
            resolvedUserId,
            params.latitude,
            params.longitude,
            params.accuracyMeters || null,
            params.message || null,
            params.timestamp || null,
        ]
    );

    const event = result.rows[0];

    const eventWithUser = {
        id: event.id,
        userId: event.user_id,
        latitude: parseFloat(event.latitude),
        longitude: parseFloat(event.longitude),
        accuracyMeters: event.accuracy_meters,
        message: event.message,
        status: event.status,
        createdAt: event.created_at,
        user: {
            name: userRecord.name,
            phone: userRecord.phone,
            email: userRecord.email,
            medicalConditions: userRecord.medical_conditions,
            allergies: userRecord.allergies,
            emergencyContacts: userRecord.emergency_contacts,
        },
    };

    // Emit sos:new event to connected admin clients
    emitSosEvent('sos:new', eventWithUser);

    return eventWithUser;
};

/**
 * Update SOS event status and create audit log
 */
export const updateSosStatus = async (
    id: string,
    status: string,
    adminUserId: string,
    adminName: string
) => {
    // Get current event data
    const currentResult = await pool.query('SELECT * FROM sos_events WHERE id = $1', [id]);

    if (currentResult.rows.length === 0) {
        return null;
    }

    const currentEvent = currentResult.rows[0];
    const previousStatus = currentEvent.status;

    // Update event status with appropriate timestamp
    let timestampField = '';
    if (status === 'acknowledged') {
        timestampField = ', acknowledged_at = NOW()';
    } else if (status === 'resolved') {
        timestampField = ', resolved_at = NOW()';
    }

    const result = await pool.query(
        `UPDATE sos_events 
     SET status = $1 ${timestampField}
     WHERE id = $2
     RETURNING *`,
        [status, id]
    );

    const updatedEvent = result.rows[0];

    // Create audit log
    await pool.query(
        `INSERT INTO audit_logs (event_type, user_id, sos_event_id, payload)
     VALUES ('sos_status_change', $1, $2, $3)`,
        [
            adminUserId,
            id,
            JSON.stringify({
                previousStatus,
                newStatus: status,
                adminName,
                timestamp: new Date().toISOString(),
            }),
        ]
    );

    // Get user details
    const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [
        updatedEvent.user_id,
    ]);
    const user = userResult.rows[0];

    const eventWithUser = {
        id: updatedEvent.id,
        userId: updatedEvent.user_id,
        latitude: parseFloat(updatedEvent.latitude),
        longitude: parseFloat(updatedEvent.longitude),
        accuracyMeters: updatedEvent.accuracy_meters,
        message: updatedEvent.message,
        status: updatedEvent.status,
        createdAt: updatedEvent.created_at,
        acknowledgedAt: updatedEvent.acknowledged_at,
        resolvedAt: updatedEvent.resolved_at,
        user: {
            name: user.name,
            phone: user.phone,
            email: user.email,
            medicalConditions: user.medical_conditions,
            allergies: user.allergies,
            emergencyContacts: user.emergency_contacts,
        },
    };

    // Emit sos:update event to connected admin clients
    emitSosEvent('sos:update', eventWithUser);

    return eventWithUser;
};
