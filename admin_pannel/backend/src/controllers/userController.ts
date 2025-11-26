/**
 * User controller
 * Handles user-related operations
 */

import { Response } from 'express';
import pool from '../config/database';
import { User } from '../types';
import { AuthRequest } from '../middleware/auth';

/**
 * GET /api/users/:id
 * Get user details by ID (admin only)
 */
export const getUserById = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;

        const result = await pool.query<User>(
            `SELECT id, name, phone, email, role, medical_conditions, allergies, 
              emergency_contacts, created_at, updated_at
       FROM users WHERE id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const user = result.rows[0] as any; // PostgreSQL returns snake_case

        return res.json({
            success: true,
            data: {
                id: user.id,
                name: user.name,
                phone: user.phone,
                email: user.email,
                role: user.role,
                medicalConditions: user.medical_conditions,
                allergies: user.allergies,
                emergencyContacts: user.emergency_contacts,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            },
        });
    } catch (error) {
        console.error('Get user error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
