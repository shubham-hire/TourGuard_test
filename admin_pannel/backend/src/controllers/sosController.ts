/**
 * SOS controller
 * Handles SOS event operations (CRUD)
 */

import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import * as sosService from '../services/sosService';

/**
 * GET /api/sos
 * List SOS events with optional filtering
 */
export const listSosEvents = async (req: Request, res: Response) => {
    try {
        const { status, since } = req.query;

        const events = await sosService.listSosEvents({
            status: status as string | undefined,
            since: since as string | undefined,
        });

        return res.json({
            success: true,
            data: events,
        });
    } catch (error) {
        console.error('List SOS events error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};

/**
 * GET /api/sos/:id
 * Get single SOS event details
 */
export const getSosEventById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const event = await sosService.getSosEventById(id);

        if (!event) {
            return res.status(404).json({ error: 'SOS event not found' });
        }

        return res.json({
            success: true,
            data: event,
        });
    } catch (error) {
        console.error('Get SOS event error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};

/**
 * POST /api/sos
 * Create new SOS event (from mobile app)
 */
export const createSosEvent = async (req: Request, res: Response) => {
    try {
        const { userId, latitude, longitude, accuracy, message, timestamp, user } = req.body;
        const configuredKey = process.env.INTEGRATION_KEY;
        if (configuredKey) {
            const providedKey =
                (req.header('x-integration-key') || req.header('x-integration-secret') || '').toString();
            if (providedKey !== configuredKey) {
                return res.status(401).json({ error: 'Invalid integration key' });
            }
        }

        const event = await sosService.createSosEvent({
            userId,
            externalUser:
                user && user.externalId
                    ? {
                          externalId: user.externalId,
                          name: user.name,
                          phone: user.phone,
                          email: user.email,
                          medicalConditions: user.medicalConditions,
                          allergies: user.allergies,
                          emergencyContacts: user.emergencyContacts,
                      }
                    : undefined,
            latitude,
            longitude,
            accuracyMeters: accuracy,
            message,
            timestamp,
        });

        return res.status(201).json({
            id: event.id,
            userId: event.userId,
            latitude: event.latitude,
            longitude: event.longitude,
            accuracy: event.accuracyMeters,
            message: event.message,
            status: event.status,
            createdAt: event.createdAt,
        });
    } catch (error) {
        console.error('Create SOS event error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};

/**
 * PATCH /api/sos/:id
 * Update SOS event status (acknowledge/resolve)
 */
export const updateSosStatus = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const adminUserId = req.user?.userId;
        const adminName = req.user?.email; // You can fetch full name from DB if needed

        const event = await sosService.updateSosStatus(
            id,
            status,
            adminUserId || '',
            adminName || ''
        );

        if (!event) {
            return res.status(404).json({ error: 'SOS event not found' });
        }

        return res.json({
            success: true,
            data: event,
        });
    } catch (error) {
        console.error('Update SOS status error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
